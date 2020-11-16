# RHV and RHHI Foo

## Build Profile
It seems best to NOT try and pre-emptively do any of the networking in advance (bonding and such).  Only plumb the primary interface (eno1, in this case) and leave the rest unmanaged via Kickstart.  You will add them later.

## RHV Config (specific to OCP IPI)
There are some interesting *quirks* about managing an IPI installation on RHV - which, makes sense as you process it.  Things such as the name of the cluster, etc...


### Prep
Cleanup old host keys
```
NODES="neo trinity morpheus"
for NODE in $NODES
do 
  sed -i -e "/$NODE/d" /Users/jradtke/.ssh/known_hosts.matrix.lab
done
for NODE in $NODES
do 
  ssh-copy-id $NODE.matrix.lab
done
```

NOTE: I use iTerm2 on Mac, ssh to all 3 nodes, then use Command-Shift-I to send the following commands to ALL 3 nodes at once.

```
# Subscribe to Satellite
DOMAIN="matrix.lab"
SATELLITE="rh7-sat6-srv01"
ORGANIZATION="MATRIXLABS"
yum clean all; subscription-manager clean
curl --insecure --output katello-ca-consumer-latest.noarch.rpm https://${SATELLITE}.${DOMAIN}/pub/katello-ca-consumer-latest.noarch.rpm
yum -y localinstall katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org="${ORGANIZATION}"  --username='admin' --password='NotAPassword' --auto-attach --force
subscription-manager repos --disable="*" --enable=rhel-7-server-rhvh-4-rpms

case `hostname -s` in
  neo) storageip=172.16.10.11;;
  trinity) storageip=172.16.10.12;;
  morpheus) storageip=172.16.10.13;;
esac

## SETUP BOND (IF NEEDED)
bond_setup() {
BONDINTERFACE="bond0"
nmcli conn delete $BONDINTERFACE 
nmcli conn delete "System ens3f0"
nmcli conn delete "System ens3f1"
nmcli con add type bond con-name $BONDINTERFACE ifname $BONDINTERFACE
nmcli con modify id bond0 bond.options mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3
nmcli con modify bond0 ipv4.address ${storageip}/24 ipv4.method manual
nmcli con add type bond-slave ifname "ens3f0" con-name "System ens3f0" master bond0
nmcli con add type bond-slave ifname "ens3f1" con-name "System ens3f1" master bond0
nmcli conn up bond0
}

cat << EOF >> /etc/hosts
# Manual Entries
10.10.10.11 neo.matrix.lab neo
10.10.10.12 trinity.matrix.lab trinity 
10.10.10.13 morpheus.matrix.lab morpheus 
172.16.10.11 neo-storage.matrix.lab
172.16.10.12 trinity-storage.matrix.lab
172.16.10.13 morpheus-storage.matrix.lab
EOF

echo | ssh-keygen -trsa -b2048 -N ''
for HOST in neo trinity morpheus; do ssh-copy-id $HOST.matrix.lab; done
for HOST in neo trinity morpheus; do ssh-copy-id $HOST-storage.matrix.lab; done
for HOST in neo trinity morpheus; do ssh $HOST.matrix.lab "uptime"; done
for HOST in neo trinity morpheus; do ssh $HOST-storage.matrix.lab "uptime"; done
```

## MANAGE STORAGE
- To see if your storage is blacklisted, try partitioning and adding a PV to each device
```
for DISK in sdb sdc sdd; do parted -s /dev/$DISK mklabel gpt mkpart pri ext4 2048s 100% set 1 lvm on; done
for DISK in sdb sdc sdd; do pvcreate /dev/${DISK}1 ; done
for DISK in sdb sdc sdd; do wipefs -af /dev/$DISK; done
for DISK in sdb sdc sdd; do parted -s /dev/$DISK print; done
```

Need to blacklist the internal disks (NOTE: you *may* not want to exclude the OS disk - testing 2020-10-13)
```
cp /etc/multipath.conf /etc/multipath.conf-`date +%F`
echo "blacklist {" >> /etc/multipath.conf
multipath -l | egrep 'SATA|SSD' | awk '{ print "  wwid " $1 }' >> /etc/multipath.conf
echo "}" >> /etc/multipath.conf
systemctl restart multipathd
multipath -l
for DISK in sdb sdc sdd; do wipefs -af /dev/$DISK; done
for DISK in sdb sdc sdd; do parted -s /dev/$DISK print; done
```

## The actual install
Browse to 
https://neo.matrix.lab:9090

Select Arbiter for data | vmstore
Select JBOD
Select Enable Dedupe & Compression for data | vmstore
engine | /dev/sdb | 150 (default is 100)
data | /dev/sdd | 900 
vmstore | /dev/sdc | 450

