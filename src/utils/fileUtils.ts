/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import * as parsers from "@stoplight/spectral-parsers";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";

export type RuleFileFormat = "json" | "yaml" | "javascript" | "unknown";

/**
 * Reference: https://github.com/projectkudu/kudu/wiki/Azure-runtime-environment
 * Reference: https://stackoverflow.com/a/39240447
 */

export function createTempRuleFile(ruleFileContent: string): string {
    return createTempFile("ruleset.yaml", ruleFileContent);
}

export function createTempFile(fileName: string, fileContent: string): string {
    const tempFilePath = path.join(os.tmpdir(), fileName);
    fs.writeFileSync(tempFilePath, fileContent, { encoding: "utf8" });

    return tempFilePath;
}

export async function fetchFile(url: string): Promise<string> {
    const response = await fetch(url);
  
    if (!response.ok) {
      throw new Error(`Failed to fetch file from ${url}. Status: ${response.status}`);
    }
  
    const data = await response.text();
    return data;
}

export function determineSpecFormat(specContent: string): RuleFileFormat {
    try {
        JSON.parse(specContent);
        return "json";
    } catch (e) {
        try {
            parsers.parseYaml(specContent);
            return "yaml";
        } catch (e) {
            try {
                eval(specContent);
                return "javascript";
            } catch (e) {
                return "unknown";
            }
        }
    }
}

