

# How do we use Heptio Ark

[Heptio Ark](https://github.com/heptio/ark) is the backup solution we used originally, and is described in this repo. It takes backups by storing the manifests in an Azure Blob Storage and creates snapshots of the persistent disks. With this information we can restore the state of the cluster/workload.

## Note

SDP-aks has migrated its backup solution from Heptio Ark to Velero. 
It is now recommended to download Velero and use the command ``` velero install ``` to get Velero running in your cluster from scratch.

If you wish to migrate your existing Ark v0.10 you will need to follow the guides below with some modification (mostly namespace related):
[0.10 -> 0.11.1 migration](https://velero.io/docs/v0.11.0/migrating-to-velero/) and
[0.11.1 -> 1.0 migration](https://velero.io/docs/v1.0.0/upgrade-to-1.0/)

## Backup
Our prod cluster uses this backup schema;  
```
ark schedule create prod-ns --schedule "0 1 * * *" --include-namespaces prod
ark schedule create staging-ns --schedule "30 1 * * *" --include-namespaces staging
ark schedule create dev-ns --schedule "0 2 * * *" --include-namespaces dev
ark schedule create monitoring-ns --schedule "30 2 * * *" --include-namespaces monitoring
```
### Take backup

Before we can restore files we need a backup, this can be done with a one off or a schedule. To create the schedule the basic syntax is `ark backup create NAME`.
This command takes a full backup of the whole cluster.

We can further define what to take backup of with arguments. Get the whole list with `ark backup create --help`.

- Backup a namespace do

```
ark backup create NAME --include-namespace NAMESPACE
```

- Backup all but namespace

```
ark backup create NAME --exclude-namespace NAMESPACE
```

- Backup a resource in namespace

```
ark backup create NAME --include-namespace NAMESPACE --include-resource RESOURCE
```

- Backup based on label

```
ark backup create NAME --selector KEY=VALUE
```

- Backup only lasts 12hours

```
ark backup create NAME --include-namespace NAMESPACE --selector KEY=VALUE --ttl 12h
```

### Schedule backups

The one of backup is a useful feature, but the bread and butter of backups is the scheduled backups. To create a backup schedule once a day at 01:00.

```
ark schedule create NAME --schedule "0 1 * * *" --include-namespace NAMESPACE
```

Schedule reference

```
| Character Position | Character Period | Acceptable Values |
| -------------------|:----------------:| -----------------:|
| 1                  | Minute           | 0-59,*            |
| 2                  | Hour             | 0-23,*            |
| 3                  | Day of Month     | 1-31,*            |
| 4                  | Month            | 1-12,*            |
| 5                  | Day of Week      | 0-7,*             |
```

As you can see we can define namespace, or any of the other parameters we use with one of backups.

## Restore

To restore a backup it often is useful to delete the resource in the cluster before we restore it to minimize conflicts. With Ark we need to "create" a restore in the same fashion as we create backups.

```
ark restore create --from-backup NAME # or --from-schedule if backup was scheduled
```

This will try to restore the full contents of this backup. If we only want to restore parts of the backup we use the same arguments as for taking backup. E.g. `ark restore create --from-backup NAME --include-resources persistentvolume,persistentvolumeclaim`

## How-to's

### List backups and schedules

- List backups
  `ark backup get`
- List schedules
  `ark schedule get`

### Migrate a service with PV from Cluster A to Cluster B
1. Allow vnet for B in the storageaccount. This is easiest done in the Azure portal. StorageAccount --> Firewalls --> +Add existing virtual network
2. Deploy the ark manifests from A in cluster B, but with the extra args "--restore-only" in ark-deployment.yaml
3. Inject the "ark-creds"-secret from A to B.  E.g; `kubectl get secrets -n infrastructure arkcreds -o yaml` and then apply in B.
4. Restore the PV into B. `ark restore create --from-backup myBackup`(The restored pv will be in the old resource-group, this can be moved in Azure portal)
5. Edit the `claimRef:` of the restored PV. This will allow the PV to be used by a PVC you specify. Note that size and storageClass must match.
6. You can now recreate the PVC, and it will bind to the restored PV. This can be done with `helm delete --purge myService`.
```
$ kubectl edit pv myPVToRestore
	  claimRef:
		apiVersion: v1
		kind: PersistentVolumeClaim
		name: <MY-PVC-NAME>
		namespace: <PVC-NS>
		resourceVersion: <copied from old pv, not sure if it matters>
		uid: <LEAVE-EMPTY>
```
### Restore HelmRelease that creates secrets (wordpress)

Some Helm charts creates secrets on creation, and will try to do this when restored with HelmRelease and Flux. An example of this is the wordpress helm chart. To restore the wordpress chart this procedure worked in testing.

We assume you know what backup to restore and that wordpress has the label `release=wordpress`, we assume the backup is called `wordpress`.

- Start by restoring the helmrelease (and namespace if you have deleted this)
  `ark restore create --from-backup wordpress --include-resources namespace,helmrelease --wait`
  This command will restore the namespace and helmrelease, when the helmrelease has been restored it will create statefulset, deployments, pvc and pv and more.
- Remove the generic resources created by helmrelease after you have made sure they have been created (`kubectl -n NAMESPACE get all -l release=wordpress`)
  `kubectl -n NAMESPACE delete pvc,po,svc,ing,deployment,replicaset,statefulset,secrets -l release=wordpress`
  This wil remove all generic resources created and make sure you have a clean environment to restore the original resources
- Restore the backed up resources after making sure the original persistent volumes has been deleted (`kubectl -n NAMESPACE get pv | grep wordpress`)
  `ark restore create --from-backup wordpress --exclude-resources=namespace,helmrelease,pod --wait`
  This will restore everything except what we already have recreated and the pods (that will be created new anyway).

After some time the Wordpress environment should come back up. Give it a few minutes.
