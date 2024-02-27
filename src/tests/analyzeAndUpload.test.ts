import { InvocationContext } from "@azure/functions";
import * as path from "path";
import { analyzeAndUploadAsync } from "../analyzeAndUpload";
import TestApiCenterClient from "./testHelpers/TestApiCenterClient";

// no timeout if running in debug mode
if (process.env.DEBUG === 'jest') {
    jest.setTimeout(5 * 60 * 1000);
}

describe("Test for the API Analysis Logic", () => {
    let context: InvocationContext;
    let apiCenterClient: TestApiCenterClient;

    beforeEach(() => {
        context = ({ log: jest.fn() } as unknown) as InvocationContext;
    });

    it("should analyze the spec file based on a simple yaml ruleset and provide results", async () => {
        // Arrange
        const testSpecFilePath = path.join(__dirname, "..", "tests", "resources", "testSpec.json");
        const testRulesetFilePath = path.join(__dirname, "..", "tests", "resources", "oas.yaml");
        apiCenterClient = new TestApiCenterClient(testSpecFilePath);
        const options =
        {
            apiDefinitionResource: {
                subscriptionId: "testresourceId",
                resourceGroup: "testresourceGroup",
                serviceName: "testserviceName",
                workspaceName: "testworkspaceName",
                apiName: "testapiName",
                apiVersion: "testapiVersion",
                apiDefinition: "testapiDefinition"
            },
            rulesetFilePath: testRulesetFilePath,
            apiCenterClient: apiCenterClient
        };

        // Action
        await analyzeAndUploadAsync(options, context);

        // Assertion
        const analysisReport = apiCenterClient.getApiAnalysisReport();
        expect(analysisReport).toBeDefined();
        expect(analysisReport.results).toBeDefined();
        expect(analysisReport.results.length).toBeGreaterThan(0);
    });

    it("should analyze the spec file based on a simple json ruleset and provide results", async () => {
        // Arrange
        const testSpecFilePath = path.join(__dirname, "..", "tests", "resources", "testSpec.json");
        const testRulesetFilePath = path.join(__dirname, "..", "tests", "resources", "oas.json");
        apiCenterClient = new TestApiCenterClient(testSpecFilePath);
        const options =
        {
            apiDefinitionResource: {
                subscriptionId: "testresourceId",
                resourceGroup: "testresourceGroup",
                serviceName: "testserviceName",
                workspaceName: "testworkspaceName",
                apiName: "testapiName",
                apiVersion: "testapiVersion",
                apiDefinition: "testapiDefinition"
            },
            rulesetFilePath: testRulesetFilePath,
            apiCenterClient: apiCenterClient
        };

        // Action
        await analyzeAndUploadAsync(options, context);

        // Assertion
        const analysisReport = apiCenterClient.getApiAnalysisReport();
        expect(analysisReport).toBeDefined();
        expect(analysisReport.results).toBeDefined();
        expect(analysisReport.results.length).toBeGreaterThan(0);
    });
});
