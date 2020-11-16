# OpenShift Container Platform 4

## "Hardware Requirements"

### OCP and OCS Cluster
| Machine       | Operating System  | vCPU | Virtual RAM | Storage | Qty        |   | vCPU | RAM | Storage 
|:--------------|:------------------|:----:|:------------|:--------|:-----------|:-:|-----|:----|:-------
| Bootstrap     | RHCOS             | 4    | 16 GB       | 120 GB  | 1          | - | 4    | 16  | 120
| Control plane | RHCOS             | 4    | 16 GB       | 120 GB  | 3          | - | 12   | 48  | 360
| Compute       | RHCOS or RHEL 7.6 | 2    | 8 GB        | 120 GB  | 3          | - | 6    | 24  | 360
|               |                   |      |             |         | **totals** | = | 22   | 88  | 840

### ACM Cluster
| Machine       | Operating System  | vCPU | Virtual RAM | Storage | Qty        |   | vCPU | RAM | Storage 
|:--------------|:------------------|:----:|:------------|:--------|:-----------|:-:|------|:----|:-------
| Bootstrap     | RHCOS             | 4    | 16 GB       | 120 GB  | 1          | - | 4    | 16  | 120
| Control plane | RHCOS             | 4    | 16 GB       | 120 GB  | 3          | - | 12   | 48  | 360
| Compute       | RHCOS or RHEL 7.6 | 4    | 12 GB       | 120 GB  | 3          | - | 12   | 36  | 360
|               |                   |      |             |         | **totals** | = | 24   | 84  | 840
* Totals represents "steady-state" - therefore, the bootstrap system is not in the summary (aside from the disk allocated)

From the Install Docs
* Although these resources use 856 GB of storage, the bootstrap node is destroyed during the cluster installation process. A minimum of 800 GB of storage is required to use a standard cluster.

##  PreReq validation

### DNS Entries
```
nslookup api.ocp4-mwn.matrix.la
nslookup test.apps.ocp4-mwn.matrix.lab
```

## References
[Installing Bare Metal](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#minimum-resource-requirements_installing-bare-metal) I struggled to find min requirememnts - this was the only place I found find any "hardware requirements"

[Installing vSphere Installer Provisioned - Cluster Resources](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere-installer-provisioned.html) Overview of "hardware requirements" as a total

