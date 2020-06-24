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

Github Actions are setup to deploy any changes to the ARM-templates from `prod` branch.
Authentication is done using the `Apply-ARMTemplate` servicePrincipal.
The templates are set to be none-destructable, meaning they can only create resources, not remove them.

## Developing ARM templates

Recommended software to develop ARM templates: VScode + ARM extension + ARM Template Viewer extension
Alternatively - Visual Studio --> create new ARM project (requires Azure extension)

### Testing

To test your templates, run the `az deployment`-command with `validate` on the specific template  

```bash
az deployment group validate -g sdpaks-dev --template-file arm-templates/base/deploy-aks.json --parameters arm-templates/dev/deploy-aks.parameters.json --debug

```
