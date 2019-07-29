# How do we use Velero

[Velero](https://github.com/heptio/velero) is the backup solution we use to backup our cluster. It takes backups by storing the manifests in an Azure Blob Storage and creates snapshots of the persistent disks. With this information we can restore the state of the cluster/workload.

## Backup
Our prod cluster uses this backup schema;  
```
velero schedule create prod-ns --schedule "0 1 * * *" --include-namespaces prod
velero schedule create staging-ns --schedule "30 1 * * *" --include-namespaces staging
velero schedule create dev-ns --schedule "0 2 * * *" --include-namespaces dev
velero schedule create monitoring-ns --schedule "30 2 * * *" --include-namespaces monitoring
```
### Take backup

Before we can restore files we need a backup, this can be done with a one off or a schedule. To create the schedule the basic syntax is `velero backup create NAME`.
This command takes a full backup of the whole cluster.

We can further define what to take backup of with arguments. Get the whole list with `velero backup create --help`.

- Backup a namespace do

```
velero backup create NAME --include-namespaces NAMESPACE
```

- Backup all but namespace

```
velero backup create NAME --exclude-namespaces NAMESPACE
```

- Backup a resource in namespace

```
velero backup create NAME --include-namespaces NAMESPACE --include-resource RESOURCE
```

- Backup based on label

```
velero backup create NAME --selector KEY=VALUE
```

- Backup only lasts 12hours

```
velero backup create NAME --include-namespace NAMESPACE --selector KEY=VALUE --ttl 12h
```

### Schedule backups

The one of backup is a useful feature, but the bread and butter of backups is the scheduled backups. To create a backup schedule once a day at 01:00.

```
velero schedule create NAME --schedule "0 1 * * *" --include-namespace NAMESPACE
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

To restore a backup it often is useful to delete the resource in the cluster before we restore it to minimize conflicts.
In SDP-aks' case the Kubernetes manifests are controlled by Flux and will automatically reapply. In this case it is best to scale down a deployment, delete a PVC then 
 With velero we need to "create" a restore in the same fashion as we create backups.

```
velero restore create --from-backup NAME # or --from-schedule if backup was scheduled
```

This will try to restore the full contents of this backup. If we only want to restore parts of the backup we use the same arguments as for taking backup. E.g. `velero restore create --from-backup NAME --include-resources persistentvolume,persistentvolumeclaim`

Say for example that the volume of your deployment named "verdaccio" has gone corrupt. You only wish to restore the volume without altering other deployments in the cluster. For this use the label selector, -l

```
velero restore create --from-schedule prod-ns --include-resources persistentvolume,persistentvolumeclaim -l release=verdaccio
```


## How-to's

### List backups and schedules

- List backups
  `velero backup get`
- List schedules
  `velero schedule get`

### Migrate a service with PV from Cluster A to Cluster B
1. Allow vnet for B in the storageaccount. This is easiest done in the Azure portal. StorageAccount --> Firewalls --> +Add existing virtual network
2. Install Velero (if not already done) in B using the bootstrap.azcli file ** remember to edit out a line as to not overwrite the existing service principal for cluster A! ** Make sure that the BackupStorageLocation and VolumeStorageLocations specified match the ones created in A. Without this Velero will not be able to locate the backups in cluster B.
3. Inject the "velero-creds"-secret from A to B.  E.g; ```kubectl get secrets -n infrastructure velerocreds -o yaml ``` and then apply in B. You might have to modify the `AZURE_RESOURCE_GROUP` part.
4. Restore the PV into B. ```velero restore create --from-backup myBackup``` this will create a new PV in B. The PV's name will be identical to the original in A, but the duplicated resource will point to a newly created Azure Disk in B's resource group named 'restore_xxx'.


### Restore HelmRelease that creates secrets (wordpress)

Some Helm charts creates secrets on creation, and will try to do this when restored with HelmRelease and Flux. An example of this is the wordpress helm chart. To restore the wordpress chart this procedure worked in testing.

We assume you know what backup to restore and that wordpress has the label `release=wordpress`, we assume the backup is called `wordpress`.

- Start by restoring the helmrelease (and namespace if you have deleted this)
  `velero restore create --from-backup wordpress --include-resources namespace,helmrelease --wait`
  This command will restore the namespace and helmrelease, when the helmrelease has been restored it will create statefulset, deployments, pvc and pv and more.
- Remove the generic resources created by helmrelease after you have made sure they have been created (`kubectl -n NAMESPACE get all -l release=wordpress`)
  `kubectl -n NAMESPACE delete pvc,po,svc,ing,deployment,replicaset,statefulset,secrets -l release=wordpress`
  This wil remove all generic resources created and make sure you have a clean environment to restore the original resources
- Restore the backed up resources after making sure the original persistent volumes has been deleted (`kubectl -n NAMESPACE get pv | grep wordpress`)
  `velero restore create --from-backup wordpress --exclude-resources=namespace,helmrelease,pod --wait`
  This will restore everything except what we already have recreated and the pods (that will be created new anyway).

After some time the Wordpress environment should come back up. Give it a few minutes.