# Backup routines for Velero

[Velero](https://github.com/heptio/velero) is the backup solution we use to backup our cluster.
Velero backups should be tested as one cannot blindly trust untested backups.

## Disaster recovery

Most sdp-aks resources including secrets can be restored or recreated easily with Flux. The exception to this are persistent volumes (PVs)

Say for example that the volume of your deployment "verdaccio-verdaccio" has gone corrupt. 
You only wish to restore the volume without altering other deployments in the cluster.

* First, scale down your deployment

`kubectl scale deployments/verdaccio-verdaccio --replicas=0` 

* Next, delete the PVC which points to the corrupted PV.  Note that the `-l release=verdaccio` will delete any PVC containing the label `release: verdaccio`

`kubectl delete pvc -l release=verdaccio`

* After this is done, attempt to restore 

`velero restore create --from-schedule prod-ns --include-resources persistentvolume,persistentvolumeclaim -l release=verdaccio`

This will recreate the PVC and with a new PV, which in turn points to a newly created Azure Disk "restore-xxx-yyy". 

* Scale back up your deployment, and be patient (may take a few minutes)

`kubectl scale deployments/verdaccio-verdaccio --replicas=1` 
`kubectl get deployments --watch`

Check out the log files for your deployment if the restore is not successful.

### Troubleshooting 
In some cases you might need to delete the entire deployment as opposed to just the PVC. We reccomend doing this only after you've tried the steps above.

`kubectl delete deployment verdaccio/verdaccio`
`velero restore create --from-schedule prod-ns -l release=verdaccio`:

In case the latest backup from schedule is corrupted, manually enter a backup name instead

`velero backup get`
`velero restore create --from-backup prod-ns-xxx-yyy -l release=verdaccio`

## Regular backup testing

### Pre-reqs:
* Two AKS clusters with a velero deployment each. The deployments should have a connection to the same storage account in Azure.
 This can be set up from scratch (with some manual config) using the `/sdp-aks/velero/bootstrap.azcli` script.
* Empty namespace in dev cluster named `backup-sandbox`
* Backup created in prod cluster containing one or more PVs.

#### Dev cluster:

* Make sure that your velero deployment is in restore-only mode:

```kubectl patch deployment velero -n infrastructure --patch '{"spec": {"template": {"spec": {"containers": [{"name": "velero","args": ["server", "--restore-only"]}]}}}}' ```

* Run the following command from the infrastructure namespace. This restores the backup into the backup-sandbox namespace.

`velero restore create  --from-backup prod-ns-longlived-xxx --namespace-mappings prod:backup-sandbox`

* To figure out where your pod has mounted its PV, use the command

`kubectl exec -it $(kubectl get pods -o name | grep -m1 verdaccio-verdaccio | cut -d'/' -f 2) -- '/bin/sh' -c "df -h" `

The volume will have a size slightly smaller than what is declared in the PVC. For instance a PVC of 8.0 Gi will be listed at a size of 7.7G.

* Next copy metadata from the pod with the mounted volume to your local machine.

```kubectl exec -it $(kubectl get pods -o name | grep -m1 verdaccio-verdaccio | cut -d'/' -f 2) -- '/bin/sh' -c "ls -laR  /verdaccio/storage" >> ./DevDiff```

Where `verdaccio-verdaccio` is the name of your kubernetes deployment, and `/verdaccio/storage` is the path to where the PV is mounted.

* You can now cleanup your dev cluster, or do so at a later time

`kubectl delete ns backup-sandbox`

#### Prod cluster:

Switch K8s context to your prod cluster, and execute the same command.

```kubectl exec -it $(kubectl get pods -o name | grep -m1 verdaccio-verdaccio | cut -d'/' -f 2) -- '/bin/sh' -c "ls -laR  /verdaccio/storage" >> ./ProdDiff```

Finally, compare the two files using your favorite diff tool. Have in mind that there may have been changes between the time of your backup and what is now running in production.
