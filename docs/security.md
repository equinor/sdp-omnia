# Security considerations

## Azure Portal
* Equinor security standard for login
* Limit user in the "SDP Tools" subscriptions

## AKS Nodes
* Not exposed to Internet
* Security updates w/ automatic reboot
* Limit VNET access to Storage account only
!* Harden with Puppet 
!* Filter and monitor audit logs

## Kubernetes
* K
!* Wassap with masters?
!* RBAC - Look into service account improvements

## Services/Pods
* Secrets stored as SealedSecrets in Github
!* Don't use latest tags
!* Pod Security
