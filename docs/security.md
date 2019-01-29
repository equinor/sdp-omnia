# Security considerations
This document describes some of the security considerations that have gone into SDP's AKS deployment.  
We have identified four main levels of concern that are, to a degree, unique to the AKS/Kubernetes technologies: The Azure Portal, The AKS Nodes, Kubernetes and Cluster Supporting Services, and Pods and Applications.  
For each of these levels we will describe the main threats, and the most important security measures to remedy these threads.  
The CIS(Center for Internet Security) Benchmarks have been used as a guideline for this work. Primarily the "CIS Benchmark for Ubuntu Linux 16.04 LTS", the "CIS Benchmark for Containers", and the "CIS Benchmark for Kubernetes".

## Azure Portal
### Threats
* Accidental deletion/misconfiguration of resources or entire cluster
* Unauthorized access to Azure resources
### Measures
* TODO: Limit user in the "SDP Tools" subscriptions, or get own subscriptions 
* Equinor security standard for Azure Portal/az CLI login (Equinor organization + Two-factor authentication(2FA))

## AKS Nodes
### Threats
* 
* 
### Measures
* !TODO: Disabled/uninstalled all unnecessary services
* !Confirm: Removed unnecessary users
* The K8s cluster runs in a virtual network protected by a Azure Network Security Group firewall. This firewall only allows ports 80 and 443 inbound.
* !(confirm this)The nodes are configured to use the 'unattended-upgrades' package for automatic seurity patching.
* Automatically reboots if nessecary to apply security updates.
* !Consider: IDS (like AIDE)
* !Consider: local Firewall
* !TODO: Filter and monitor audit logs. Log events that modify date&time, user&groups, AppArmor, login&logout, access rights, unsuccessful authorization, docker files
* !Consider: Ensure file permissions. Eg. /etc/passwd, /etc/shadow, /etc/crontab
* !Consider: Enforce AppArmor
* !Confirm: Restrict traffic between containers (Docker daemon)

## Kubernetes and Cluster Supporting Services
### Threats
* 
### Measures
* Master nodes w/cluster services in AKS is fully managed by Azure.  
* TODO: RBAC - Look into service account improvements
* Keep up-to-date
* !Consider: NetworkPolicies
* TODO: Don't allow dangerous runtime options. This include mounting the docker socket, using priviliged flag, --pid=host, --network=host, --device. This can be done with PodSecurityPolicy
* TODO: Ensure kubelet configuration files permissions
* Consider: NetworkPolicies

## Pods and Applications
### Threats
* 
### Measures
* Secrets stored as SealedSecrets in Github
* TODO: Don't use latest tags
* Consider: Pod Security (Is this the same as docker run's --security-opt where you can specify an AppArmor profile?)
* !TODO: Set resource limits for all pods
* Untrusted Images
* Vulnerability scanned images
* Untrusted HelmCharts
