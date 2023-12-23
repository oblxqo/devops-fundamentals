# IaC



## Comparison Table:

| Tool           |     Language & Tools     | Ease of Use | Clear to Understand |    Costs    | Community & Support | Maturity |                             Issues                              |
|:---------------|:------------------------:|:-----------:|:-------------------:|:-----------:|:-------------------:|:--------:|:---------------------------------------------------------------:|
| Docker Compose |           YAML           |    Easy     |         Yes         |    Free     |   Large community   |  Mature  |     Environment setup can be complex and resource-intensive     |
| CodeBuild      |           YAML           |  Moderate   |         Yes         | Pay-per-use |  Excellent support  |  Mature  |   Limited customization options and third-party integrations    |
| GitLab CI      |           YAML           |    Easy     |         Yes         |    Free     |    Good support     |  Mature  | Limited support for complex workflows and customization options |
| CloudFormation |        JSON, YAML        |  Moderate   |         Yes         |    Free     |  Excellent support  |  Mature  |              Limited support for non-AWS resources              |
| AWS CDK        | TypeScript, Python, etc. |  Moderate   |         Yes         |    Free     |    Good support     |  Mature  |  Learning curve for developers not familiar with the language   |
| Terraform      |           HCL            |  Moderate   |         Yes         |    Free     |   Large community   |  Mature  |             Slower execution speed compared to CDK              |

Proposed tools for the project:

Docker Compose can be used to define and manage the containers required for the local environment. It allows you to define the services, networks, and volumes required for the project.
CodeBuild for build automation and quality checks, considering its close integration with other AWS services.
CloudFormation for infrastructure management, as it provides native support for AWS resources and is well-supported by the community and AWS.
If Multi-Cloud Management or the use of a familiar programming language is a priority, AWS CDK or Terraform could be viable alternatives.
Also Terraform allows for flexible infrastructure provisioning across multiple cloud providers.
