/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import * as path from "path";

/// Customizable constants

/** File name for your ruleset file, this should correspond to the file name in the `resources/rulesets` folder */
export const RulesetFileName = "oas.yml";
/** Folder name for your ruleset file, this should correspond to the folder name in the `resources` folder */
export const RulesetFolderName = "rulesets";


/// Non-customizable constants

// Note: __dirname is the dir name for the compiled javascript folder "{workspaceFolder}/dist/src/"
export const FullRulesetFilePath = path.join(__dirname, "..", "..", "resources", RulesetFolderName, RulesetFileName);
export const DefaultApiVersion = "2024-03-01";
export const SpectralAnalyzerName = "spectral";
export const ManagementApiEndpoint = "management.azure.com";
export const ApiAnalysisAzureFunctionName = "apicenter-analyzer";
