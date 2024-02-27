/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { UploadAnalysisStateResponseContract } from "../contracts/UploadAnalysisStateResponseContract";
import { UpdateAnalysisStateOptions } from "./ApiCenterClient";

export interface IApiCenterClient {
    updateAnalysisStateAsync(options: UpdateAnalysisStateOptions): Promise<UploadAnalysisStateResponseContract>;
    getApiSpecificationFileContentAsync(): Promise<string>;
}
