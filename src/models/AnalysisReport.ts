/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

export type Severity = "error" | "warning" | "information" | "hint";

export interface ErrorRange {
    /**
     * The start position of the error in the OpenAPI document.
     * "0:0" means line:0,character:0
     */
    start?: string;

    /**
     * The end position of the error in the OpenAPI document.
     * "0:126" means line:0, character:126
     */
    end?: string;
}

export interface Details {
    /**
     * The range of the error in the OpenAPI document. e.g. {"start":"0:0","end":"0:126"}
     */
    range?: ErrorRange;
}

export interface AnalysisResult {
    /**
     * The type of linter that failed analysis. e.g. "spectral"
     */
    analyzer?: string;

    /**
     * Error message for the rule that failed analysis. e.g. "Operation must have at least one 2xx or 3xx response..."
     */
    description?: string;

    /**
     * The name of the rule that failed analysis. e.g. "operation-success-response"
     */
    analyzerRuleName?: string;

    /**
     * The severity of the rule that failed analysis. e.g. "error"
     */
    severity?: Severity;

    /**
     * The URL of the rule that failed analysis. e.g. "https://github.com/stoplightio/spectral/blob/develop/docs/reference/openapi-rules.md#operation-success-response"
     */
    docUrl?: string;

    /**
     * The details of the rule that failed analysis.
     */
    details?: Details;
}

export interface AnalysisReport {
    results: AnalysisResult[];
}
