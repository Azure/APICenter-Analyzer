/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import type { ISpectralDiagnostic } from "@stoplight/spectral-core";
import { SpectralAnalyzerName } from "../constants";
import { AnalysisResult, Severity } from "../models/AnalysisReport";

/**
 * Converts the spectral output to a uniform format that API Center uses
 * @param spectralOutput The output from the spectral linter
 * @returns The uniform format
 */
export function convertToUniformResults(spectralOutput: ISpectralDiagnostic[]): AnalysisResult[] {
    const uniformResults: AnalysisResult[] = [];

    spectralOutput.forEach((spectralDiagnostic) => {
        const uniformResult: AnalysisResult = {
            analyzer: SpectralAnalyzerName,
            description: spectralDiagnostic.message,
            analyzerRuleName: String(spectralDiagnostic.code),
            severity: convertSeverityNumberToString(spectralDiagnostic.severity),
            docUrl: null,
            details: {
                range: {
                    start: `${spectralDiagnostic.range.start.line}:${spectralDiagnostic.range.start.character}`,
                    end: `${spectralDiagnostic.range.end.line}:${spectralDiagnostic.range.end.character}`
                }
            }
        };

        uniformResults.push(uniformResult);
    });

    return uniformResults;
}

/**
 * Converts the severity number to a string
 * @see {@link https://docs.stoplight.io/docs/spectral/9ffa04e052cc1-spectral-cli#json-formatter} for the format of the output
 */
function convertSeverityNumberToString(severity: number): Severity {
    switch (severity) {
        case 0:
            return "error";
        case 1:
            return "warning";
        case 2:
            return "information";
        case 3:
            return "hint";
        default:
            return "error";
    }
}
