# VMware
If you're looking for a VMware SME, look elsewhere ;-)
I need to be proficient enough that I have *some* idea of what my customers are seeing.

## Getting Started
Install your ESXi nodes and configure networking/storage/etc for basic settings...

## Enable/Configure Core Infrastructure Services  
### SNMP
I use libreNMS to monitor my hosts, which is solely SNMP based.

```
esxcli system snmp set --communities public,publicRO --syslocation HomeLab --syscontact cloudxabide@gmail.com
esxcli system snmp set --enable true
```

### NTP
You ABSOLUTELY should use NTP  
https://kb.vmware.com/s/article/57147

## Deploy vCenter

### Using OSX
NOTE: while this is (probably) not necessary, I would mount the vCenter ISO and copy the contents to a local directoy on my Mac.  
In finder, traverse to VMware-VCSA-all-6.7.0-14367737 | vcsa-us-installer | mac 
Click on Installer, follow defaults  
Select "Embedded Platform Services Controller"  
Select "Tiny" for Deployment Size

Proceed to Stage 2  
NOTE:  If your VCSA install is interrupted, you may be able to resume at  
https://vmw-vcenter6.matrix.lab:5480/

Create new SSO domain  
* Single Sign-On domain name:  vsphere.matrix.lab 
* Single Sign-On user name:  administrator  
* Single Sign-On password:  NotAPassword  
NOTE:  I do not know this for certain, but.. I think you are asking for trouble using *.local for the SSO domain name.

## Networking
I actually learned something today about LACP (which might be specific to VMware) - the implementation still limits a single "stream" to the bandwidth of a single interface (apparently due to the algorithm).  It's fairly complicated to setup and manage and since I am not managing VMware on a daily basis, I am not going to bother.  Now I need to figure out what to do alternatively (LBT seems to be the consensus).

### Clustered host(s)
| Host     | IP (MGMT)   | IP (Guest)  | IP Storage   |
|:---------|:-----------:|:-----------:|:------------:|
| dozer    | 10.10.10.14 | 10.10.10.34 | 172.16.10.34 |
| tank     | 10.10.10.15 | 10.10.10.35 | 172.16.10.35 |

### Add Virtual Distributed Port Group/Virtual Switch
#### Create New Distributed Virtual Switch (dVS)
Click on the new DVS (DSwitch-Guest) | Configure | LACP 
Click "+ NEW" 
* name: (whatever)
* number of ports: 2
* Mode: Passive
* Load Balancing Mode: (Default)

#### Add Hosts to DVS

## Certificate nightmare
If you rebuild your environment as often as I do, I think you will experience the same issues with the browsers and cert

https://www.virtuallyghetto.com/2016/07/automating-the-import-of-vcenter-server-6-x-root-certificate.html  
NOTE/WARNING:  OF course you should review the script I am recommending (and teh following steps)  
```
wget https://raw.githubusercontent.com/lamw/vghetto-scripts/master/shell/import-vcrootcertificate.sh
wget https://fqdn_of_vca/certs/download.zip
unzip downloads.zip; cd certs/mac;
./import-vcrootcertificate.sh

```
Unzip them

## Account Management (users/groups)
Here is the example from VMware's doc
```
localaccounts.user.add --role operator --username test1 --password --fullname TestName --email test1@mymail.com
```

{operator|admin|superAdmin}
```
localaccounts.user.add --role operator --username ocpipi --password "NotAPassword" --fullname "OCP4 IPI Installer" --email root@matrix.lab

```

## Lab Specific Links
https://10.10.10.130:5480/ui/monitor/cpuandmem

## References
[About vCenter Server Installation and Setup](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vcenter.install.doc/GUID-8DC3866D-5087-40A2-8067-1361A2AF95BD.html)  
[Using the partedUtil command line utility on ESXi and ESX (1036609)](https://kb.vmware.com/s/article/1036609)    
[Deploying the vCenter Server Appliance and Platform Services Controller Appliance](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vcenter.install.doc/GUID-F06BA415-66D8-42CD-9151-701BBBCE8D65.html) << 6.7 release    
[Configure a Link Aggregation Group to Handle the Traffic for Distributed Port Groups](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.networking.doc/GUID-45DF45A6-DBDB-4386-85BF-400797683D05.html)  
[Configure SNMP Communities](https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.monitoring.doc/GUID-24F04690-CAF9-45DD-ACB6-3F361B312828.html)    
[Create a Local User Account in the vCenter Server Appliance](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.vcsa.doc/GUID-533AE852-A1F9-404E-8AC6-5D9FD65464E5.html)    
[vSphere Permissions and User Management Tasks](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.security.doc/GUID-5372F580-5C23-4E9C-8A4E-EF1B4DD9033E.html)  

## Appendix
## Managing the internal disks
This section is probably not something most folks will run in to.  I use these systems for ALL kinds of stuff (RHEL, RHV, VMware, etc...) and the disk utils do not always play nicely.

### Wiping the unused disks
I'm not entirely certain why VMware modified the standard Linux behavior for addressing disks, but.. you are NOT going to find /dev/sdb, /dev/sdc, etc..

I *think* this an acceptable way to address the disk(s) and get their partition table

```
# for DISK in `find /vmfs/devices/disks/vm* | grep -v \:`; do echo "$DISK" >> mydisks.txt; done
# for DISK in `cat mydisks.txt `; do echo $DISK; partedUtil getptbl $DISK; done
/vmfs/devices/disks/vml.01000000003138303531353132303030353830202020202020534154412053
gpt
14593 255 63 234441648
1 64 8191 C12A7328F81F11D2BA4B00A0C93EC93B systemPartition 128
5 8224 520191 EBD0A0A2B9E5443387C068B6B72699C7 linuxNative 0
6 520224 1032191 EBD0A0A2B9E5443387C068B6B72699C7 linuxNative 0
7 1032224 1257471 9D27538040AD11DBBF97000C2911D1B8 vmkDiagnostic 0
8 1257504 1843199 EBD0A0A2B9E5443387C068B6B72699C7 linuxNative 0
9 1843200 7086079 9D27538040AD11DBBF97000C2911D1B8 vmkDiagnostic 0
2 7086080 15472639 EBD0A0A2B9E5443387C068B6B72699C7 linuxNative 0
3 15472640 234441614 AA31E02A400F11DB9590000C2911D1B8 vmfs 0

/vmfs/devices/disks/vml.01000000003139313231323438303032393035202020202020534154412053
unknown
58369 255 63 937703088

/vmfs/devices/disks/vml.01000000003139313231323438303033313030202020202020534154412053
unknown
58369 255 63 937703088

/vmfs/devices/disks/vml.01000000003230303531333130323433343331202020202020534154412053
unknown
124519 255 63 2000409264
```

As you can see (above), there are 3 disks which have "unknown" partition tables (and not "gpt" like the first).  No bueno

```
for DISK in `find /vmfs/devices/disks/vm* | grep -v \:`; do echo "$DISK" >> mydisks.txt; done
for DISK in `cat mydisks.txt `; do echo $DISK; partedUtil getptbl $DISK; done
for DISK in `cat mydisks.txt `; do echo $DISK; partedUtil mklabel $DISK gpt; done
```
