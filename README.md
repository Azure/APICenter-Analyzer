[![Open Source Love](https://firstcontributions.github.io/open-source-badges/badges/open-source-v1/open-source.svg)](https://github.com/firstcontributions/open-source-badges)

# Analyze your API Specs with Azure API Center (Preview)

## Overview

- :bulb: [What is Azure API Center?](./#bulb-what-is-azure-api-center)
  - :memo: API Governance & Azure API Center
  - :memo: API Analysis in Azure API Center (Overview)
- :rocket: [How to Run](./#rocket-how-to-run-api-analysis)
  - :wrench: Configure your environment
  - :wrench: Running the sample using the Azure Developer CLI (azd)
  - :wrench: Configure & run your function locally
- :package: [How to deploy](./#package-how-to-deploy)
- :page_facing_up: [Custom Ruleset](./#page_facing_up-custom-ruleset)
- :pencil2: [Contributing](./#pencil2-contributing)
- :sunny: [Bugs & Issues & Feedback](./#sunny-bugs--issues--feedback)
- :construction: [Code of Conduct](./#construction-code-of-conduct)
- :ok_hand: [Trademark Notice](./#ok_hand-trademark-notice)
- :mag: [Telemetry](./#mag-telemetry)

## :bulb: What is Azure API Center?

[Azure API Center](https://learn.microsoft.com/en-us/azure/api-center/overview) is a service that helps you develop and maintain a structured inventory of your organization’s APIs. With API Center, you can track all of your APIs in a centralized location, regardless of their type, lifecycle stage, or deployment location. API Center enables API discovery, reuse, and governance empowering API Platform Teams.

### :memo: API Governance & Azure API Center

API governance is a critical aspect of managing APIs across an organization. It involves establishing and enforcing policies and procedures that guarantee the quality, consistency, security, and compliance of APIs. Effective API governance not only maximizes the value of an organization's API portfolio but also reduces complexity, eliminates redundancy, and mitigates potential risks.

For API Platform Teams, governance is crucial as it guides them in designing, building, and deploying APIs that align with the organization's objectives, standards, and best practices.

To facilitate robust API governance, we're excited to introduce **API Analysis** in Azure API Center. API Analysis employs API linting, a technique that validates your API specifications against a predefined set of rules or standards. With API Analysis, you can ensure your APIs adhere to your organization's guidelines and best practices, making them consistently secure and compliant.

> API Analysis currently supports OpenAPI v2, v3.x, and AsyncAPI specifications uploaded as JSON or YAML files.

### :memo: API Analysis in Azure API Center (Overview)

Here is a high-level overview of how API analysis works in Azure API Center
![Overview](./images/overview.png)

## :rocket: How to Run API Analysis

### :wrench: Configure your environment

Before you get started, make sure you have the following requirements in place:

- An Azure account with an active subscription. [Create an account for free](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio).
- [Node.js 18.x](https://nodejs.org/en/download/releases/) or above. Use the `node --version` command to check your version.
- [TypeScript 4.x](https://www.typescriptlang.org/). Use the `tsc -v` command to check your version.
- [Visual Studio Code](https://code.visualstudio.com/) on one of the [supported platforms](https://code.visualstudio.com/docs/supporting/requirements#_platforms).
- The [Azure Functions extension v1.10.4](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions) or above for Visual Studio Code.
- [Azure Functions Core Tools v4.0.5382 or above](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-typescript#install-the-azure-functions-core-tools).
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd).
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli).

### :wrench: Running the sample using the Azure Developer CLI (azd)

The Azure Developer CLI (`azd`) is a developer-centric command-line interface (CLI) tool for creating Azure applications.

After logging in with the following command, you will be able to use the `azd` cli to quickly provision and deploy the application.

```
# Authenticate with Azure Developer CLI
azd auth login

# Authenticate with Azure CLI
az login
```

Then, run `azd up` to provision all the resources to Azure and deploy the code to those resources.

```
azd up
```

Enter an environment name and select your desired `subscription` and `location`. Then choose whether to create the monitoring resources. If you want to use an existing api center resource, pass the values for `apiCenterName` and `apiCenterResourceGroupName`. Otherwise leave them blank to create a new one. Wait a moment for the resource deployment to complete. Then you can upload your own api definition for test.

There are four scenarios:

1. New `APIC` with `monitoring`. You need to leave `apiCenterName` and `apiCenterResourceGroupName` blank and set `useMonitoring` to "True".
2. New `APIC` without `monitoring`. You need to leave `apiCenterName` and `apiCenterResourceGroupName` blank and set `useMonitoring` to "False".
3. Existing `APIC` with `monitoring`. You need to fill in `apiCenterName` and `apiCenterResourceGroupName` with an existing resource and set `useMonitoring` to "True".
4. Existing `APIC` without `monitoring`. You need to fill in `apiCenterName` and `apiCenterResourceGroupName` with an existing resource and set `useMonitoring` to "False".

(Optional) You can also set the Env variables manually using the following command to skip setting them during the `azd up` process.

```
azd env set USE_MONITORING <true/false>

azd env set APIC_NAME <your-api-center-name>

azd env set APIC_RESOURCE_GROUP_NAME <your-api-center-resource-group-name>
```

You can also run the sample directly locally (See below).

### :wrench: Configure & run your function locally

- Clone the APICenter-Analyzer repository to your local machine.
- Open the Project in Visual Studio Code
- Set a breakpoint
- To start the function locally, press `F5` or the Run and Debug icon in the left-hand side Activity bar. The Terminal panel should display the Output from Azure Functions Core Tools.
- Follow the instructions in [Test your Event Grid handler locally](https://learn.microsoft.com/en-us/azure/communication-services/how-tos/event-grid/local-testing-event-grid) to trigger the function.

## :package: How to deploy

Follow the instructions in [Quickstart: Create a function in Azure with TypeScript using Visual Studio Code](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-typescript?pivots=nodejs-model-v4#sign-in-to-azure). Start from the "Sign in to Azure" section and complete all subsequent sections.

## :page_facing_up: Custom Ruleset

This template provides you with the default OAS (OpenAPI Specification) ruleset from Spectral. To see the exact rules within the ruleset, see [OpenAPI Rules](https://docs.stoplight.io/docs/spectral/4dec24461f3af-open-api-rules).

If you want to customize your Ruleset for analysis, simply swap out the default ruleset file oas.yaml located in `{workSpaceFolder}/resources/rulesets` with any valid Spectral ruleset file. We accept all valid Spectral formats (YAML, JSON, and JavaScript). Afterward, head over to the `{workSpaceFolder}/src/constants.ts` file and update the `RulesetFileName` constant with your chosen ruleset file name.

## :pencil2: Contributing

See [the contribution guidelines](CONTRIBUTING.md) for ideas and guidance on how to improve the template. Thank you!

## :sunny: Bugs & Issues & Feedback

We Love Hearing From You!

Your feedback is invaluable to us, and we encourage you to share your thoughts and suggestions in the repository's **Issues** section. You can also report bugs or submit feature requests there. Rest assured, we’ll be keeping a close eye on your input to continuously improve. While we’re dedicated to monitoring these issues, please note that this channel is not part of our Microsoft Azure Service Support.

**Microsoft Azure Support** assistance is limited to the initial setup of the Azure Function app that runs the linting engine. Best effort support is provided for problems that are caused by environmental factors, such as (but not limited to): hosting platform, development environment, network configuration.

If you need technical assistance with extending the linting engine or improving existing rules , please leverage existing technical communities such as Stack Overflow. We don't provide support through GitHub Issues.

We welcome and appreciate community contributions.

## :construction: Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## :ok_hand: Trademark Notice

Trademarks This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft’s Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.

## :mag: Telemetry

Data Collection. The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkID=824704. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## License

[MIT](LICENSE.txt)

---
page_type: sample
languages:
- azdeveloper
- typescript
- javascript
- powershell
- bash
- bicep
products:
- azure
- azure-functions
- azure-blob-storage
urlFragment: APICenter-Analyzer
name: Azure API Center Analyzer
description: Analyze your API Specs with Azure API Center (Preview)
---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/en-us/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->
