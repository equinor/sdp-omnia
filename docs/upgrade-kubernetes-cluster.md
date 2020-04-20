# Upgrade Kubernetes cluster

If you need to upgrade the cluster these are the minimal steps needed. Make sure your cluster has at least 2 nodes before upgrading. If not, the applications running will not have any chance of starting on another node while one is beeing upgraded.

- If you run on only one node, scale up to at least two nodes.  
  `az aks scale --name $AZ_AKS_NAME --node-count 2`

- Then find the upgrade path, make sure to upgrade to the highest possibe version from the version you currently use.  
  `az aks get-versions --location $AZ_LOCATION --output table`

- To run cluster upgrade do the following.  
  `az aks upgrade --name $AZ_AKS_NAME --kubernetes-version VERSION`

- Remember to update .env file with the latest Kubernetes version after last upgrade

- If cluster was scaled up then remember to scale down cluster accordingly
