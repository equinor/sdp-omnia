# Software Development Platform's Cloud platform

This is the main repository for SDP's cloud platform.

It has two parts:
- AKS solution
- VM's with on-prem connectivity.

This repo mostly focuses on AKS, as the VM's are here mostly for legacy support. New apps and services should always be placed in the AKS solution if possible.
We conver some basic overview information on these topics;

- How AKS works
- How we have configured it
- Which additional tools we have integrated with the cluster
- Scripts and ARM-templates to recreate the clusters.

## Related Repositories

Flux GitOps Manifests - <https://github.com/equinor/sdp-flux>  


The Flux repo should be considered as the "source of truth" of what is actually deployed in the cluster.

## Technologies

![Architecture](/docs/sdp-aks.png)
AKS Stack with example services

### AKS

With AKS, Azure provides virtual machines running Ubuntu preconfigured with Kubernetes setup as a cluster. AKS also includes the preconfigured Azure resources _Network security group_, _Route table_, _Disk_, _Network interface_, _Virtual network_, _Public IP address_, and _Load balancer_. The K8s master node(s) are fully controlled by Azure. This include etcd, kube-scheduler, kube-controller-manager, and the kube-apiserver.

### Helm

On top of Kubernetes we run Helm. Helm is a way of deploying configurable _packages_ of K8s manifests into a K8s cluster.

### Flux

To operate a K8s cluster that has a _Single Source of Truth_, deploy K8s resources in a _declarative way_, and provide _configuration traceability_, we use [FluxCD/Flux](https://github.com/fluxcd/flux) as a GitOps controller. This ensures that the cluster state mirrors the configuration in our Git repository.

### VMware velero

To backup both Persistent Volumes and K8s manifests, we deploy Vmware Velero. Velero is configured with a seperate Azure Resource group and Storage account. Velero runs on a schedule to take snapshots of the Azure Disks and the deployed K8s manifests.

### Grafana & Prometheus
To collect metrics we use Prometheus. We display these graphically in Grafana. For collecting logs we use Grafana Loki, and collect both logs from our VM's and in-cluster resources. We also display our log output centrally through Grafana, so that we can use a "single pane of glass" for logs and metrics for as many of our services as possible.

### Sealed Secrets

To be able to maintain our GitOps workflow, we need to commit secrets(SSL Keys, Oauth keys, Container Registry Keys etc.) to Git. These secrets are encrypted with asymmetric cryptography, where the private key only resides within the Sealed-Secrets controller in the K8s cluster. We deploy SealedSecret, which picks up encrypted secrets and "translates" them into regular K8s secrets.

### External-DNS

Is simply a service that read ingress manifest annotations, and talks to the Cloud provider to automatically creat DNS records.

### Ingress-Controller

We use Nginx ingress-controller to expose services from within the cluster to the Internet. The ingress-controllers main job is to connect hostnames and K8s services, and terminate SSL traffic. Port 22 is opened to support SSH cloning from our Gitlab instance.

### Cert-Manager

Cert-Manager reads ingress manifests annotations and creates a SSL certificate and key for a given hostname. We have configured our cert-manager to order certificates from Let'sEncrypt.

### Node-Puppet

This is a homemade solution that gives us the capacity to controll the AKS nodes via Puppet. It works by running a DaemonSet that uses a InitContainer to install Puppet and subscribe it to our Puppet Git repository.

### Kured

Kured is a simple solution to the problem on rebooting nodes to enable security patches. If an update requires the node to restart, it creates a file that Kured looks for. If the file is there, Kured drains, restart, and then uncordons the given node.

### Loki

Loki allows us to collect logs from both in-cluster pods and VM's outside the cluster. We forward the logs to Grafana where we can centrally search and correlate metrics and logs.

### Sysdig technologies

OSS Falco and Sysdig Inspect are used to gain security insight and packet captures in case of incidents. Falco exporter collects metrics and forwards them to Grafana for visualization and correlation with logs collected by Loki.

### Oauth2-proxy
For services which do not have sufficient built-in authentication, we use an Oauth2-proxy to ensure proper access restrictions.

### VMs

In the /arm-templates/classic folder you will find ARM templates for our VM's which not run in a separate subscription. These run apps which require on-prem connectivity to function. This separate subscription has stricter policies, so currently we cannot use a CI job to automatically update our templates. This will be valid until when service principals can use JiT access, and can do this via the CLI.

## Usage

### Prerequisite

- Install Azure CLI (az)
- Install kubectl; `az aks install-cli`
- Install [helm client](https://helm.sh/docs/intro/install/)  

Note: Installing and using kubectl commands does not work through the Equinor proxy. You should therefore be on the 'approved network' to avoid the proxy.

### Cluster Setup

1. Make sure the Azure Key Vault is created
2. Create and populate `.env` from `env.template`
3. Bootstrap AKS with additional dependencies `./bootstrap.sh`
4. Further updates should be done to the ARM templates. The CI will automatically apply updates when committing so make sure you commit to dev before merging into prod.
  
## How-to's

- Get access to created cluster
  - `az aks get-credentials --resource-group $AZ_GROUP --name $AZ_AKS_NAME`  
  This populates `~/.kube/config` with certs and keys
- [Expand Persistent Volume Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
- [Upgrade Flux](/docs/upgrade-flux.md)
- Check Helm charts for updates
  1. `helm plugin install https://github.com/bacongobbler/helm-whatup` 
  2. `helm whatup`
- Changing run settings for Flux (e.g. branch or repository)  
To change the branch Flux uses, you "upgrade" Flux and set some variables.
  1. Find the installed version of Flux  
  `helm list --all flux`  
  2. `helm upgrade flux --reuse-values --set git.branch=dev fluxcd/flux`
- [Upgrade Kubernetes cluster](/docs/upgrade-kubernetes-cluster.md)
- Revoke Let's Encrypt Certificates
  1. Extract key and cert to PEM-format  
 `kubectl get secret my-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 --decode > crt.pem`  
 `kubectl get secret my-tls-secret -o jsonpath='{.data.tls\.key}' | base64 --decode > key.pem`
  2. Issue revoke request  
  `sudo certbot revoke --cert-path ./crt.pem  --key-path ./key.pem`
- Usage of VMware velero Backup solution
  1. [Configuration](/docs/velero.md)
  2. [Disaster recovery and backup testing](/docs/velero-backup-routine.md)
