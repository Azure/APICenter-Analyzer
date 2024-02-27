/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { app, EventGridEvent, InvocationContext } from "@azure/functions";
import { analyzeAndUploadAsync } from "../analyzeAndUpload";
import ApiCenterClient from "../client/ApiCenterClient";
import { ApiAnalysisAzureFunctionName, FullRulesetFilePath } from "../constants";
import { parseResourceId } from "../utils/armResourceIdUtils";

export async function apiAnalyzerFunction(event: EventGridEvent, context: InvocationContext): Promise<void> {
    context.log('Event grid function processed event:', event);

    if (!event) {
        throw new Error('Event data is not valid');
    }

    const apiDefinitionResource = parseResourceId(event.subject);
    const apiCenterClient = new ApiCenterClient(apiDefinitionResource, context);

    context.log('Calling analyzer function');
    await analyzeAndUploadAsync(
        {
            apiDefinitionResource: apiDefinitionResource,
            rulesetFilePath: FullRulesetFilePath,
            apiCenterClient: apiCenterClient
        },
        context
    );
}

app.eventGrid(ApiAnalysisAzureFunctionName, {
    handler: apiAnalyzerFunction
});
