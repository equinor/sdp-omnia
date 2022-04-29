# Upgrade Kubernetes cluster

If you need to upgrade the cluster these are the minimal steps needed. Make sure your cluster has at least 2 nodes before upgrading. If not, the applications running will not have any chance of starting on another node while one is beeing upgraded.

- Then find the upgrade path, make sure to upgrade to the highest possible version from the version you currently use.  
  `az aks get-versions --location $AZ_LOCATION --output table`

- Version should be upgraded by updating the arm-templates/base/deploy-aks template. For minor version upgrades you should always test the new version in dev first.
  If the pipeline is struggling for some reason (Give it time, upgrade can take about an hour), then you may try to upgrade by using the az CLI.

- To run cluster upgrade 'manually', do the following.  
  `az aks upgrade --name $AZ_AKS_NAME --kubernetes-version VERSION`

- FluxCD should also be upgraded to match supported kubernetes versions. See <https://fluxcd.io/docs/installation/>
