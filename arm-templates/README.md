# ARM templates

ARM Templates are IaC for the Azure platform. They are idempotent.
If you are used to scripts and are sceptical, know this: Any administrative task you do through the portal, CLI or REST API are just wrappers for abstracted ARM templates. Using ARM templates directly provide a declarative, idempotent and more granular control of your infrastructure.

A detailed intro to IaC on Azure can be found here https://github.com/starkfell/100DaysOfIaC

## Info and limitations

Please note that ARM templates are not perfect. They do not contain state, for this you should use Terraform, which has its own limitations. Also, just as the CLI and portal, you cannot do illegal operations. E.g. decreasing the size of a VM in an AKS cluster "just because I can" in the arm-template. 

These templates are currently resource-level group templates. It is possible to create subscription-level templates (e.g. declare all your resource groups and resources in a single file)
This creates a bit more complexitiy and work, but can absolutely be done

## Update infrastructure
In practice - idempotency means that you make a change in the template, run the deployment through one of the methods below, update your changes to Github. Ideally we should run this through a CI/CD pipeline.

**TODO**: Update Infrastructure automatically using Azure pipelines

**Deploying this template can be done in several ways:**

Powershell + Azure module installed - Two choices

- `./Deploy-AzureResourceGroup.ps1 "westeurope"` (Recommended)
- Or `New-Azdeployment -Name "DeploymentX" -Location "West Europe" -TemplateParameterFile "./azuredeploy.parameters.json" -TemplateFile "./azuredeploy.json"`

The Powershell Script can be easily reused for other templates by adding the following parameters in the command line:
```
-ResourceGroupName x
-TemplateFile y
-TemplateParametersFile z
```

Azure CLI:

`az group deployment create --resource-group <resource-group-name> --template-file "./azuredeploy.json" --parameters "./azuredeploy.parameters.json"`

Visual Studio:
Right click the .deployproj file and select "Deploy" for a more graphical visualization

Graphical:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/equinor/sdp-aks/master/arm-templates/deploy-psql.json" target="_blank">
  <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https://raw.githubusercontent.com/equinor/sdp-aks/master/arm-templates/deploy-psql.json" target="_blank">
  <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a>

## Developing ARM templates

Recommended software to develop ARM templates: VScode + ARM extension + ARM Template Viewer extension
Alternatively - Visual Studio --> Open the .deployproj file. (requires Azure extension)