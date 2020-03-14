# ARM templates

ARM Templates are IaC for the Azure platform. They are idempotent.
If you are used to scripts and are sceptical, know this: Any administrative task you do through the portal, CLI or REST API are just wrappers for abstracted ARM templates. Using ARM templates directly provide a declarative, idempotent and more granular control of your infrastructure.

A detailed intro to IaC on Azure can be found here https://github.com/starkfell/100DaysOfIaC

## Set up

In true GitOps fashion, arm templates should be synced regularly, and Dev and Prod should also be in sync.
Put common values - e.g. default ARM-template in the /base folder. Put "diffs" - parameter files in /development or /production folders. 

## Info and limitations

Please note that ARM templates are not perfect. They do not contain state, for this you should use Terraform, which has its own limitations. Also, just as the CLI and portal, you cannot do illegal operations. E.g. decreasing the size of a VM in an AKS cluster "just because I can" in the arm-template. 
To see changes applied by an ARM template, see https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-deploy-what-if

The ARM templates are grouped per resource group. The exception is "deploy-arm.json", which is the main template to be called from Github Actions. This template links to the other ARM templates, and has dependencies so everything should run smoothly from scratch to fully deployed cluster.


## Update infrastructure
In practice - idempotency means that you make a change in the template, run the deployment through one of the methods below, update your changes to Github. Ideally we should run this through a CI/CD pipeline.

**TODO**: Update Infrastructure automatically using Azure pipelines

**Deploying this template can be done in several ways:**

Powershell + Azure module installed

   `New-Azdeployment -Name "DeploymentX" -Location "Norway East" -TemplateFile "./deploy-arm.json" -TemplateParameterFile "./deploy-arm.parameters.json"`


Azure CLI:

`az group deployment create --resource-group <resource-group-name> --template-file "./deploy-arm.json" --parameters "./deploy-arm.parameters.json"`

## Developing ARM templates

Recommended software to develop ARM templates: VScode + ARM extension + ARM Template Viewer extension
Alternatively - Visual Studio --> create new ARM project (requires Azure extension)