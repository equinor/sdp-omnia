# Upgrade Flux

Per Aug. 2020 - Flux is now in two separate helm releases - flux and helm-operator

Use the following commands to upgrade the Flux installed in cluster. Remember to upgrade fluxctl to latest version in case of breaking changes
```
# Get latest variables
source .env

# Upgrade to latest helm charts
helm repo update

# Upgrade flux in place with the same values/settings
helm upgrade flux --reuse-values fluxcd/flux
Remember to upgrade the content in post-arm.sh file.
```

If Flux fails to upgrade you need to remove Flux and install it again. But be aware that if you just try `helm delete flux` you __WILL__ get all your HelmReleases removed from the cluster. This is considered as bad. The procedure is therefore as follows.
```
# Remove the operator that is responsible for Flux Helmreleases
kubectl -n flux delete deployment/flux-helm-operator

# Remove Flux
helm delete --purge flux

# Run the post-arm bootstrap script again to install with correct values
./post-arm.sh
```

You might need to add your deployment key to the git repository. Ideally the same public key should be used, some attempts earlier have found that only the private key is re-used.  