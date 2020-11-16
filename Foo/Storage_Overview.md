# Storage Overview

My homelab is primarily focused on OpenShift, specifically 4 (at this point).

Storage in a private cloud is quite a bit more challenging than something like AWS (which just has all of the different types available).

## Storage 
### Types
File
Object
Block

### Modes
| Access Mode   | CLI abbreviation | Description 
|:- -----------:|:---:|:---------
| ReadWriteOnce | rwo | The volume can be mounted as read-write by a single node.
| ReadOnlyMany  | rox | The volume can be mounted as read-only by many nodes.
| ReadWriteMany | rwx | The volume can be mounted as read-write by many nodes.

## My Environment
As this is a humble homelab, I have limited resources available (and certainly no "Enterprise SAN Array")

Finding the optimal set of storage which is supported and functional can occupy a bit of time - which is why I am *documenting* it, so I don't have to go through this exercise if/when I rebuild my lab

### Volume Plugins
| Volume Plug-in                      | rwo | rox | rwx
| :----------------------------------:|:---:|:---:|:---:|
| iSCSI (freeNAS)                     | X   | X   | -
| NFS (freeNAS)                       | X   | X   | X
| Red Hat OpenShift Container Storage | X   | -   | X
| VMware vSphere (native)             | X   | -   | -

### Block Storage
| Volume Plug-in                      | Manual Provision | Dynamically Provisioned | Fully Supported 
| :----------------------------------:|:----------------:|:-----------------------:|:---------------:|
| iSCSI (freeNAS)                     | X   | -   | X
| NFS (freeNAS)                       | -   | -   | -
| Red Hat OpenShift Container Storage | X   | X   | X
| VMware vSphere (native)             | X   | X   | X

### Object Storage
TBC

### File Storage
TBC

## Storage driver(s) (CSI and in-tree)
### CSI
This CSI driver is fairly compelling (with some caveats).  The driver is provided/supported by the storage vendor (not Red Hat).  But, it does allow for Dynamic Provisioning - which is awesome.

## References
[OpenShift 4 - Persistent Storage CSI](https://docs.openshift.com/container-platform/4.5/storage/container_storage_interface/persistent-storage-csi.html)  
[OpenShift 4 - Understanding Persistent Storage](https://docs.openshift.com/container-platform/4.5/storage/understanding-persistent-storage.html)
