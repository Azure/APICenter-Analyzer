/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

export interface ApiDefinitionResource {
    subscriptionId: string;
    resourceGroup: string;
    serviceName: string;
    workspaceName: string;
    apiName: string;
    apiVersion: string;
    apiDefinition:string;
}


export function parseResourceId(id: string): ApiDefinitionResource {
    const definitionResourceIdRegex = /\/subscriptions\/(.*)\/resourceGroups\/(.*)\/providers\/Microsoft.ApiCenter\/services\/(.*)\/workspaces\/(.*)\/apis\/(.*)\/versions\/(.*)\/definitions\/(.*)/;
    const matches = definitionResourceIdRegex.exec(id);
    if (!matches || matches.length < 8) {
        throw new Error(`Failed to parse resource id: ${id}`);
    }

    return {
        subscriptionId: matches[1],
        resourceGroup: matches[2],
        serviceName: matches[3],
        workspaceName: matches[4],
        apiName: matches[5],
        apiVersion: matches[6],
        apiDefinition: matches[7]
    };
}
