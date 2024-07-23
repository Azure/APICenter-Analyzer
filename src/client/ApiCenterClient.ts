/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See LICENSE.md in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { InvocationContext } from "@azure/functions";
import { DefaultAzureCredential, TokenCredential } from "@azure/identity";
import { RequestPrepareOptions, ServiceClient, delay } from "@azure/ms-rest-js";
import { DefaultApiVersion, ManagementApiEndpoint } from "../constants";
import { UploadAnalysisStateResponseContract } from "../contracts/UploadAnalysisStateResponseContract";
import { AnalysisReport } from "../models/AnalysisReport";
import { AnalysisState } from "../models/AnalysisState";
import { ApiDefinitionResource } from "../utils/armResourceIdUtils";
import { fetchFile } from "../utils/fileUtils";
import { IApiCenterClient } from "./IApiCenterClient";

// TODO: Use the Azure SDK when it is implemented
const Max_Retry_Count = 3;

export interface UpdateAnalysisStateOptions {
    validationResults?: AnalysisReport;
    operationId?: string;
    state: AnalysisState;
}

class ApiCenterClient implements IApiCenterClient {
    private apiDefinitionResource: ApiDefinitionResource;
    private context: InvocationContext;

    public constructor(apiDefinitionResource: ApiDefinitionResource, context: InvocationContext) {
        this.apiDefinitionResource = apiDefinitionResource;
        this.context = context;
    }

    public async updateAnalysisStateAsync(options: UpdateAnalysisStateOptions): Promise<UploadAnalysisStateResponseContract> {
        this.context.log(`Updating analysis state to ${options.state}`);
        const requestOptions: RequestPrepareOptions = {
            method: "POST",
            url: `https://${ManagementApiEndpoint}/subscriptions/${this.apiDefinitionResource.subscriptionId}/resourceGroups/${this.apiDefinitionResource.resourceGroup}/providers/Microsoft.ApiCenter/services/${this.apiDefinitionResource.serviceName}/workspaces/${this.apiDefinitionResource.workspaceName}/apis/${this.apiDefinitionResource.apiName}/versions/${this.apiDefinitionResource.apiVersion}/definitions/${this.apiDefinitionResource.apiDefinition}/updateAnalysisState?api-version=${DefaultApiVersion}`,
            body: {
                format: "inline",
                state: options.state,
                value: options.validationResults ? JSON.stringify(options.validationResults) : ""
            }
        };

        if (options.operationId) {
            requestOptions.body.operationId = options.operationId;
        }

        const response = await this.httpRequestAsync(requestOptions);
        if (!response.operationId || !response.state) {
            throw new Error("Invalid response from server. The response does not contain the expected content.");
        }

        return response as UploadAnalysisStateResponseContract;
    }

    public async getApiSpecificationFileContentAsync(): Promise<string> {
        const options: RequestPrepareOptions = {
            method: "POST",
            url: `https://${ManagementApiEndpoint}/subscriptions/${this.apiDefinitionResource.subscriptionId}/resourceGroups/${this.apiDefinitionResource.resourceGroup}/providers/Microsoft.ApiCenter/services/${this.apiDefinitionResource.serviceName}/workspaces/${this.apiDefinitionResource.workspaceName}/apis/${this.apiDefinitionResource.apiName}/versions/${this.apiDefinitionResource.apiVersion}/definitions/${this.apiDefinitionResource.apiDefinition}/exportSpecification?api-version=${DefaultApiVersion}`,
        };

        this.context.log(`Fetching spec file with url: ${options.url}`);
        const response = await this.httpRequestAsync(options);
        if (!response.value || !response.format) {
            throw new Error("Invalid response from server. The response does not contain the expected content.");
        }

        let specContent = response.value;
        // if the format is a link, fetch the content
        if (response.format.endsWith("-link")) {
            specContent = await fetchFile(response.parsedBody.value);
        }

        return specContent;
    }

    private async httpRequestAsync(options: RequestPrepareOptions): Promise<any> {
        const credential: TokenCredential = new DefaultAzureCredential();
        const client = new ServiceClient(credential);

        let response = null;
        for (let i = 0; i < Max_Retry_Count; i++) {
            try {
                response = await client.sendRequest(options);
                if (!response || !response.parsedBody || response.status !== 200) {
                    throw new Error(`Invalid response from server. Details:
                        Status: ${response?.status || "unknown"}
                        Response:  ${JSON.stringify(response?.parsedBody) || "unknown"}`
                    );
                }

                return response.parsedBody;
            } catch (error) {
                console.error(`Attempt ${i + 1} failed. Retrying...`);
                console.error(`An error occurred while sending the request: ${error.message}`);

                // Wait for 1 second before the next attempt
                await delay(1000);
            }
        }

        throw new Error(`HTTP Request Failed. Details:
            Operation: ${options.method}: ${options.url}
            Payload: ${options.body ? JSON.stringify(options.body) : "empty"}
            Status code: ${response?.status || "unknown"}
            Response: ${response?.bodyAsText || "unknown"}`
        );
    }
}

export default ApiCenterClient;
