# Security considerations
This document describes some of the security considerations that have gone into SDP's AKS deployment.  
We have identified four main levels of concern that are, to a degree, unique to the AKS/Kubernetes technologies: The Azure Portal, The AKS Nodes, Kubernetes and Cluster Supporting Services, and Pods and Applications.  
For each of these levels we will describe the main threats, and the most important security measures to remedy these threads.

## Azure Portal
### Threats
* Accidental deletion/misconfiguration of resources or entire cluster
* Unauthorized access to Azure resources
### Measures
* TODO: Limit user in the "SDP Tools" subscriptions 
* Equinor security standard for Azure Portal/az CLI login (Equinor organization + Two-factor authentication(2FA))

## AKS Nodes
### Threats
* Unwanted Internett exposed services
* Software vulnerabilities
### Measures
* The K8s cluster runs in a virtual network protected by a Azure Network Security Group firewall. This firewall only allows ports 80 and 443 inbound.
* !(confirm this)The nodes run on Ubuntu 16.04.5 LTS. They are configured to use the 'unattended-upgrades' package, with 'Allowed-Origins' set to 'ubuntu:16.04.5_xenial-security'
* Automatically reboots on kernal security patches
* OS hardened with Puppet with guidelines from "CIS Benchmark for Ubuntu Linux 16.04 LTS"
* Container engine(Moby) hardened with "CIS Benchmark for Containers"
* Filter and monitor audit logs

## Kubernetes and Cluster Supporting Services
### Threats
* Unauthorized cluster access
* Vulnerabilities in software (Docker, Kubernetes, Helm eg.)
### Measures
* Hardened with guidelines from "CIS Benchmark for Kubernetes"
!* Wassap with masters?
!* RBAC - Look into service account improvements
* Keep up-to-date

## Pods and Applications
* Secrets stored as SealedSecrets in Github
!* Don't use latest tags
!* Pod Security
* Untrusted Images
* Vulnerability scanned images
* Untrusted HelmCharts
