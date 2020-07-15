# Backup routines for Velero

[Velero](https://github.com/heptio/velero) is the backup solution we use to backup our cluster.
Velero backups should be tested as one cannot blindly trust untested backups.

## Gitlab disaster recovery

When using Gitlab DR, data is stored three places

Azure blob storage
In cluster Gitaly disk (PV)
Managed postgres (db)

Blob storage has built-in soft deletion and geo-redundancy.

Azure postgreSQL has built-in regular Point-in-time backups.

For The PV, the easiest way to recover is simply to delete the old namespace and restore from a backup
Using another namespace will not work "just like that", because secrets connecting services typically point to a namespace. e.g. "gitlab.gitlab.svc.local"

Note that there are some issues with restoring PV's which have the "retain" mode set. THis means that even if you delete the NS, the PV is still there.
The solution to this is simply to delete all related PV's
`k delete pv xxx yyy`

`velero restore create --from-backup gitlab-ns-xxx `

This method has been tested successfully. RTO (after old NS is deleted) is about 12-15 mins. Deleting the NS takes about 5-10 mins:
Total RTO: 17-25 minutes.
RPO: 0,5-24,5 hours. We run nightly full backups. I estimate that these take max 30 minutes.

To recover the postgres database, go to the Azure portal, find your database server and click "restore"
This copies your point in time restore point to a new server.
Note that the newly generated DB does not copy over existing VNET rules, you should set these to increase security.

Remember to update the helm chart:

```
      psql:
        database: postgres
        host: sdpaks-prod-gitlab-psql.postgres.database.azure.com
        password:
          key: password
          secret: gitlab-postgres-secret
        username: gitlab@sdpaks-prod-gitlab-psql
```
You should not have to change the content of the secret, but "username" and "host" must be updated.


## Disaster recovery

Most sdp-aks resources including secrets can be restored or recreated easily with Flux. The exception to this are persistent volumes (PVs)

Say for example that the volume of your deployment "verdaccio-verdaccio" has gone corrupt. 
You only wish to restore the volume without altering other deployments in the cluster.

* First, scale down the flux deployment in your infrastructure namespace

`kubectl scale deployments/flux -n infrastructure --replicas=0  `

* Scale down your corrupted deployment

`kubectl scale deployments/verdaccio-verdaccio --replicas=0` 

* Next, delete the PVC which points to the corrupted PV.  Note that the `-l release=verdaccio` will delete any PVC containing the label `release: verdaccio`. __Also note that label tags will vary from helm chart to helm chart. Commonly used tags are "app" and "release".__

`kubectl delete pvc -l release=verdaccio`

* After this is done, attempt to restore 

`velero restore create --from-schedule prod-ns --include-resources persistentvolume,persistentvolumeclaim -l release=verdaccio`

This will recreate the PVC and with a new PV, which in turn points to a newly created Azure Disk "restore-xxx-yyy". 

* Scale back up your deployment, and be patient (may take a few minutes)

`kubectl scale deployments/verdaccio-verdaccio --replicas=1` 
`kubectl get deployments --watch`

Check out the log files for your deployment if the restore is not successful.

* If successful, scale the flux deployment back up

`kubectl scale deployments/flux -n infrastructure --replicas=0  `

### Troubleshooting 
In some cases you might need to delete the entire deployment as opposed to just the PVC. We recommend doing this only after you've tried the steps above.

`kubectl delete deployment verdaccio/verdaccio`
`velero restore create --from-schedule prod-ns -l release=verdaccio`:

In case the latest backup from schedule is corrupted, manually enter a backup name instead

`velero backup get`
`velero restore create --from-backup prod-ns-xxx-yyy -l release=verdaccio`

## Regular backup testing

### Pre-reqs:
* Two AKS clusters with a velero deployment each. The deployments should have a connection to the same storage account in Azure.
 This can be set up from scratch (with some manual config) using the `/sdp-omnia/velero/bootstrap.azcli` script.
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
