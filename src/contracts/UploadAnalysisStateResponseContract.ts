/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { AnalysisState } from "../models/AnalysisState";

export interface UploadAnalysisStateResponseContract {
    operationId: string;
    state: AnalysisState;
}
