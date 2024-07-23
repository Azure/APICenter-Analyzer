/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { InvocationContext } from "@azure/functions";
import * as spectral from "@stoplight/spectral-core";
import * as parsers from "@stoplight/spectral-parsers";
import { fetch } from "@stoplight/spectral-runtime";
import { IApiCenterClient } from "./client/IApiCenterClient";
import { ApiDefinitionResource } from "./utils/armResourceIdUtils";
import { determineSpecFormat } from "./utils/fileUtils";
import { convertToUniformResults } from "./utils/validationResultsUtils";

// Note: these are in SimpleJS format, do not use import/export
const { bundleAndLoadRuleset } = require("@stoplight/spectral-ruleset-bundler/with-loader");
const fs = require("fs");

export interface runAnalysisOptions {
    apiDefinitionResource: ApiDefinitionResource;
    rulesetFilePath: string;
    apiCenterClient: IApiCenterClient;
}

/**
 * Analyzes the API specification and uploads the results to the API Center service.
 *
 * @see {@link https://meta.stoplight.io/docs/spectral/eb68e7afd463e-spectral-in-java-script} for more information on the spectral library
 */
export async function analyzeAndUploadAsync(options: runAnalysisOptions, context: InvocationContext): Promise<void> {
    let operationId = "";
    let apiCenterClient = options.apiCenterClient;

    try {
        context.log('Starting API Analysis process.');
        const response = await apiCenterClient.updateAnalysisStateAsync({
            state: "started"
        });
        operationId = response.operationId;

        context.log(`Operation ID: ${operationId || "empty"}`);
        context.log('Fetching spec file.');
        const specFileContent = await apiCenterClient.getApiSpecificationFileContentAsync();

        context.log('Parsing spec file to determine the format.');
        var apiSpecDocument = null;
        const specFormat = determineSpecFormat(specFileContent);
        if (specFormat === "unknown") {
            throw new Error('Unknown spec format. Please ensure that the spec file is in either JSON, YAML, or JavaScript format.');
        } else if (specFormat === "json") {
            apiSpecDocument = new spectral.Document(specFileContent, parsers.Json);
        } else if (specFormat === "yaml") {
            apiSpecDocument = new spectral.Document(specFileContent, parsers.Yaml);
        }
        context.log(`The spec format is ${specFormat}`);

        context.log('Setting ruleset for spectral.');
        const spectralClient = new spectral.Spectral();
        if (specFormat === "json" || specFormat === "yaml") {
            const ruleset = await bundleAndLoadRuleset(options.rulesetFilePath, { fs, fetch });
            spectralClient.setRuleset(ruleset);
        } else {
            // @see https://meta.stoplight.io/docs/spectral/eb68e7afd463e-spectral-in-java-script#load-a-javascript-ruleset
            throw new Error('JavaScript ruleset is not yet supported.');
        }

        context.log('Performing API Analysis.');
        const analysisResults = await spectralClient.run(apiSpecDocument);

        context.log('Transforming results');
        const uniformAnalysisResults = convertToUniformResults(analysisResults);

        context.log('Uploading report');
        await apiCenterClient.updateAnalysisStateAsync(
            {
                state: "completed",
                validationResults: { results: uniformAnalysisResults },
                operationId: operationId
            }
        );

        context.log('API Analysis complete');
    } catch (error) {
        context.error(`Error occurred during API Analysis: ${error}`);
        await apiCenterClient.updateAnalysisStateAsync(
            {
                state: "failed",
                operationId: operationId
            }
        );
        throw error;
    }
}
