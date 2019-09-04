# Upgrade Flux

Use the following commands to upgrade the Flux installed in cluster. Remember to upgrade fluxctl to latest version in case of braking changes
```
# Get latest variables
source .env

# Upgrade to latest helm charts
helm repo update

# Upgrade flux in place with the same values/settings
helm upgrade flux --reuse-values fluxcd/flux
```

If Flux fails to upgrade you need to remove Flux and install it again. But be aware that if you just try `helm delete flux` you __WILL__ get all your HelmReleases removed from the cluster. This is considered as bad. The procedure is therefore as follows.
```
# Remove the operator that is responsible for FluxHelm releases
kubectl -n infrastructure delete deployment/flux-helm-operator

# Remove Flux
helm delete --purge flux

# Run Flux bootstrap script again to install with correct values
./flux/bootstrap.azcli
```

You should not need to add your deployment key to the git repository as Flux should use the same as before.