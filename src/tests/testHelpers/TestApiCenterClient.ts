/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import * as fs from "fs";
import { UpdateAnalysisStateOptions } from "../../client/ApiCenterClient";
import { IApiCenterClient } from "../../client/IApiCenterClient";
import { UploadAnalysisStateResponseContract } from "../../contracts/UploadAnalysisStateResponseContract";
import { AnalysisReport } from "../../models/AnalysisReport";

class TestApiCenterClient implements IApiCenterClient {
    private apiAnalysisReport: AnalysisReport;
    private apiSpecFilePath: string;

    constructor(apiSpecFilePath: string) {
        this.apiSpecFilePath = apiSpecFilePath;
    }

    public async updateAnalysisStateAsync(options: UpdateAnalysisStateOptions): Promise<UploadAnalysisStateResponseContract> {
        this.apiAnalysisReport = options.validationResults;

        return {
            operationId: "testOperationId",
            state: options.state
        };
    }

    public async getApiSpecificationFileContentAsync(): Promise<string> {
        const specContent = fs.readFileSync(this.apiSpecFilePath, "utf8");
        return specContent;
    }

    public getApiAnalysisReport(): AnalysisReport {
        return this.apiAnalysisReport;
    }

}

export default TestApiCenterClient;
