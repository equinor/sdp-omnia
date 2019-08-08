# Software Development Platform's Azure Kubernetes Services
This is the main repository for SDP's AKS solution.  
It contains some basic overview information on these topics;
* How AKS works
* How we have configured it
* Which additional tools we have integrated with the cluster
* Scripts to recreate the cluster with the most fundamental services.

### Related Repositories
Flux GitOps Manifests - https://github.com/equinor/sdp-flux  
AKS Puppet - https://github.com/equinor/sdp-aks-puppet  
AKS Node Puppet Setup - https://github.com/equinor/sdp-aks-node-puppet

## Technologies
![Architecture](/images/sdp-aks.png)
AKS Stack with example services
### AKS
With AKS, Azure provides virtual machines running Ubuntu preconfigured with Kubernetes setup as a cluster. AKS also includes the preconfigured Azure resources _Network security group_, _Route table_, _Disk_, _Network interface_, _Virtual network_, _Public IP address_, and _Load balancer_. The K8s master node(s) are fully controlled by Azure. This include etcd, kube-scheduler, kube-controller-manager, and the kube-apiserver.
### Helm
On top of Kubernetes we run Helm. Helm is a way of deploying configurable _packages_ of K8s manifests into a K8s cluster.
### Flux
To operate a K8s cluster that has a _Single Source of Truth_, deploy K8s resources in a _declarative way_, and provide _configuration traceability_, we use (FluxCD/Flux)[https://github.com/fluxcd/flux] as a GitOps controller. This ensures that the cluster state mirrors the configuration in our Git repository.
### Vmware velero
To backup both Persistent Volumes and K8s manifests, we deploy Vmware Velero. Velero is configured with a seperate Azure Resource group and Storage account. Velero runs on a schedule to take snapshots of the Azure Disks and the deployed K8s manifests.
### Sealed Secrets
To be able to maintain our GitOps workflow, we would like to commit secrets(SSL Keys, Oauth keys, Container Registry Keys etc.) to Git. These secrets are encrypted with asymmetric cryptography, where the private key only resides within the Sealed-Secrets controller in the K8s cluster. We deploy a CRD(Custom Resource Definition) called SealedSecret, which the controller picks up and "translates" to regular K8s secrets.
### External-DNS
Is simply a service that read ingress manifest annotations, and talks to the Cloud provider to automatically creat DNS records. 
### Ingress-Controller
We use Nginx ingress-controller to expose services from within the cluster to the Internet. The ingress-controllers main job is to connect hostnames and K8s services, and terminate SSL traffic.
### Cert-Manager
Cert-Manager reads ingress manifests annotations and creates a SSL certificate and key for a given hostname. We have configured our cert-manager to order certificates from Let'sEncrypt.
### Node-Puppet
This is a homemade solution that gives us the capacity to controll the AKS nodes via Puppet. It works by running a DaemonSet that uses a InitContainer to install Puppet and subscribe it to our Puppet Git repository.
### Kured
Kured is a simple solution to the problem on rebooting nodes to enable security patches. If an update requires the node to restart, it creates a file the Kured looks for. If the file is there, Kured drains, restart, and then uncordons the given node. 
## Usage
### Prerequisite
- Install Azure CLI (az)
- Install kubectl; `az aks install-cli`
- Install [helm client](https://docs.helm.sh/using_helm/#installing-helm)  

Note: Installing and using kubectl commands does not work through the Equinor proxy. You should therefore be on the 'approved network' to avoid the proxy.

### Cluster Setup

1. Create and populate `.env` from `env.template`
2. Create kubernetes cluster and install Helm  
  `./bootstrap.azcli`
3. Setup DNS Zone and create necessary secrets in k8s cluster.   
  `./external-dns/bootstrap.azcli`
4. Deploy Flux.  
  `./flux/bootstrap.azcli`
5. Create a Azure Container Registry.  
  `./acr/bootstrap.azcli`
6. Setup Vmware Velero backup infrastructure  
  `./velero/bootstrap.azcli`
7. You now have three files with secrets, namely `azure.json`, `acr.properties` and `velero-credentials`, secure these and share with the rest of the group
  
## How-to's
* [Use of Azure Container Registry](https://github.com/Statoil/sdp-flux/blob/basic_acr_usage/docs/ACR.md)
* Get access to created cluster
  * `az aks get-credentials --resource-group $AZ_GROUP --name $AZ_AKS_NAME`  
  This populates `~/.kube/config` with certs and keys 
* [Expand Persistent Volume Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
* [Upgrade Flux](/docs/upgrade-flux.md)
* Check Helm charts for updates
  1. `helm plugin install https://github.com/bacongobbler/helm-whatup` 
  2. `helm whatup`
* Changing run settings for Flux (e.g. branch or repository)  
To change the branch Flux uses, you "upgrade" Flux and set some variables.
  1. Find the installed version of Flux  
  `helm list --all flux`  
  2. `helm upgrade flux --reuse-values --set git.branch=dev --version 0.5.1 fluxcd/flux`
* [Upgrade Kubernetes cluster](/docs/upgrade-kubernetes-cluster.md)
* Revoke Let's Encrypt Certificates
  1. Extract key and cert to PEM-format  
 `kubectl get secret my-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 --decode > crt.pem`  
 `kubectl get secret my-tls-secret -o jsonpath='{.data.tls\.key}' | base64 --decode > key.pem`
  2. Issue revoke request  
  `sudo certbot revoke --cert-path ./crt.pem  --key-path ./key.pem`
* Usage of Vmware velero Backup solution
  1. [Configuration](/docs/velero.md)
  2. [Disaster recovery and backup testing](/docs/velero-backup-routine.md)
## Troubleshooting 

https://docs.microsoft.com/en-us/azure/aks/troubleshooting

- Port forward application  
  `kubectl port-forward --namespace default $POD_NAME $LOCAL_PORT:$APP_PORT`

- Get Token request returned http error: 400 and server response .   
    `az account clear`  
    `az login`
