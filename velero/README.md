# Information

This directory contains bootstrap scripts for setting up Velero. The script creates a storage container, service principal creates a secret and opens up a firewall exception between your AKS cluster and your Azure Storage Account.
Accurate use of your .env file is vital for generating a working secret.
Once this is completed, Velero is installed using the command "velero install xxx". This requires you to have downloaded the [velero CLI](https://github.com/heptio/velero/releases) from a tarball.

* `minio/`: Used in the [Quickstart][1] to set up [Minio][0], a local S3-compatible object storage service. It provides a convenient way to test Ark without tying you to a specific cloud provider.

# Testing backups

Currently we do not have an automated way to test our backups. It is still reccommended that you should test backups regularly. In SDP Tools case the most important thing to test are persistent volumes, as these resources are not easily recreatable without using backups.

So far we are unable to automate testing of persistent data volumes. The way to do it currently is to give a dev cluster access to the Blob storage of the prod cluster, and manually restore backups.

The [Radix platform](https://github.com/equinor/radix-platform/tree/master/scripts/velero/restore) at Equinor provides some scripts specific to the Radix platform on how to automate these restore processes.


[0]: https://github.com/minio/minio
[1]: /README.md#quickstart
