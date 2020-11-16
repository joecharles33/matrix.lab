# freeNAS

## Objective
This doc provides details on how I implemented freeNAS to provide iSCSI (block) and NFS (file) to my OpenShift Container Platform 4 environment.

Basically, a place for notes, etc...

## LACP 
My Cisco Switch had Zero Issues with LACP and for some reason my Linksys did.  Though, I believe it was an issue on the switch-side.
Anyhow - I recommend using LACP, *even* if you have 10Gb interfaces (which I do not).

## Storage Pool, Datasets, and Volumes (Shares)
Create a Zpool (zpool-raidZ)
Create Zvol(s) for iSCSI devices- I try to break them up.  Probably not necessary.
Create Dataset for NFS share(s)

### Pool
Login to the webUI
Click Storage | Pools, ADD (upper-right corner)
follow the prompts

Once the Pool has been created, Click Storage | Pools
Find your Pool, click the 3 vertical dots, Add Zvol - be sure to add a 'g' to the size

### Zvols (Block Based)
Create 3 x 400G Zvol for iSCSI devices
Browse to the Pool and click the 3 vertical dots on the right, and "Add Zvol"
follow the prompts

### Datasets (File Based)
Browse to the Pool and click the 3 vertical dots on the right, and "Add Dataset"

### Shares
#### Block Shares (iSCSI)
I use the WIZARD to create my iSCSI targets.  Without question, I would do this differently if this were a production environment.
click Sharing | Block Shares (iSCSI)

Name: lun00  
Type: Device  
Device *: select a Zvol  
what are you using this for: VMware  

#### Unix Shares (NFS)
Browse to Sharing and click on Unix Shares (NFS)
(I use "ADVANCED MODE" and will add Authorized Networks)

Update "permissions"
Click Services | NFS (and the pencil)
I selected: Allow non-root mount

Click Sharing | Unix Shares (NFS)
then the 3 vertical dots under your NFS share | Edit | Advanced Mode
Maproot User: nobody
Maproot Group: nobody

NOTES:  
I had to chmod the NFS mount on the freeNAS 
```
chmod 777 /mnt/raidZ/nfs-registry*
```

## References
https://www.ixsystems.com/documentation/freenas/11.3-U5/freenas.html


## NOTES
The following will be redone
******* 
Using 3 x 1TB drives in a RAID-Z configuration, I end up with 1.79TB.
I need storage for: 
* Guest VMs OS Drives
* Application Storage (Dynamically Provisioned from OCP 4)
* Infrastructure Storage (Dynamically Provisioned from OCP 4)
NOTE:  freeNAS recommends you do not allocate over 80% of your available space (if I understand correctly)
I am leaving space available for things like NFS shares, etc.. in case I need "file" storage for OCP

1.79TB * 80% = 1.432
******* 

#### iSCSI
| Size | Qty | Total
|:---:|:----|:-----
| 400  | 3   | 1200 

#### NFS 
TBD - I will likely end up adjusting this
| Size | Qty | Total
|:----:|:----|:-----
| 100  | 1   | 100

## References
[OpenShift 4 - Understanding Persistent Storage](https://docs.openshift.com/container-platform/4.5/storage/understanding-persistent-storage.html_)
[openshift dynamic NFS persistent volume using NFS-client-provisioner](https://medium.com/faun/openshift-dynamic-nfs-persistent-volume-using-nfs-client-provisioner-fcbb8c9344e) 

