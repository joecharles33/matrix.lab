#!/bin/sh

############### ############### ############### ###############
############### ############### ############### ###############
#                  iSCSI RHV-DATA Storage
############### ############### ############### ###############
############### ############### ############### ###############
# NOTE:  I have not quite worked through getting Autho/Authe working yet...
yum -y install selinux-policy-targeted.noarch libstoragemgmt-targetd-plugin.noarch targetcli.noarch targetd.noarch

sed -i -e 's/write_cache_state = 1/write_cache_state = 0/g' /etc/lvm/lvm.conf
sed -i -e 's/readahead = "auto"/readahead = "none"/g' /etc/lvm/lvm.conf

systemctl enable target
firewall-cmd --permanent --zone=public --add-service=iscsi-target
firewall-cmd --permanent --zone=public --add-port=3260/tcp
firewall-cmd --permanent --zone=public --add-port=860/tcp
firewall-cmd --reload

###########
# Create Volumes for Targets (LVM tasks)
LUNSIZE=200g
VGS=rhel_data
for VG in $VGS
do
  for VOLNUM in `seq 1 5`
  do
    TGT="tgt${VOLNUM}"
    echo "lvcreate -nlv_${TGT} -L${LUNSIZE} $VG "
    lvcreate -nlv_${TGT} -L${LUNSIZE} $VG
  done
lvs
done

######################################################################
# If you need to "start over"...
# targetcli clearconfig confirm=true
######################################################################
# Gather IQNS from Hypervisor(s):  cat /etc/iscsi/initiatorname.iscsi | awk -F\= '{ print $2 }'
#   AGAIN... NOTE... THE FOLLOWING LINE IS NOT GOING TO WORK... YOU NEED TO GET YOUR
#    OWN IQN FROM THE HYPERVISOR!
# NOTE: NOTE: NOTE:  READ THE LAST 3 lines...
IQNS="iqn.1998-01.com.vmware:dozer-3421cca8 iqn.1998-01.com.vmware:tank-2ef0085d"

# GLOBAL CONFIG STUFF
CMDFILE=./iscsi-globals.cmd
echo "set global auto_cd_after_create=false" > ${CMDFILE}
echo "set global auto_save_on_exit=true" >> ${CMDFILE}
echo "cd /" >> ${CMDFILE}
# GLOBAL AUTHENTICATION
#echo "cd /iscsi" >> ${CMDFILE}
#echo "set discovery_auth enable=1" >> ${CMDFILE}
#echo "set discovery_auth userid=discouser" >> ${CMDFILE}
#echo "set discovery_auth password=discopass" >> ${CMDFILE}
#echo "set discovery_auth mutual_userid=mutuser" >> ${CMDFILE}
#echo "set discovery_auth mutual_password=mutpass" >> ${CMDFILE}
echo "cd /" >> ${CMDFILE}
echo "saveconfig" >> ${CMDFILE}
echo "exit" >> ${CMDFILE}
targetcli < ${CMDFILE}

# Create command file to map the devices to targets
# RFC 3720 hostname:targetname
map_devs() {
CMDFILE=${TARGET}.cmd
# BACKSTORES
echo "cd /backstores/" > ${CMDFILE}
for DEV in `find /dev/mapper/${TARGET_VG}*lv_tgt[1][0-1]`; do echo "block/ create name=`echo ${DEV} | cut -f2,3 -d\_` dev=${DEV}"; done >> ${CMDFILE}
# INSTANTIATE ISCSI
echo "cd /iscsi" >> ${CMDFILE}
echo "create iqn.`date +%Y-%m`.`hostname | awk -F. '{ print $3"."$2"."$1 }'`:`echo ${TARGET} | sed 's/_/-/g'`.target01" >> ${CMDFILE}
echo "cd /iscsi/iqn.`date +%Y-%m`.`hostname | awk -F. '{ print $3"."$2"."$1 }'`:`echo ${TARGET} | sed 's/_/-/g'`.target01/tpg1/" >> ${CMDFILE}
# EXPORT LUNS
echo "cd luns" >> ${CMDFILE}
for DEV in `find /dev/mapper/${TARGET}*lv_tgt[1][0-1]`; do echo "create /backstores/block/`echo ${DEV} | cut -f2,3 -d\_`"; done >> ${CMDFILE}
echo "cd .." >> ${CMDFILE}
# CREATE NETWORK PORTAL (Doesn't seem to work as advertised)
# Do not CD in to portals
echo "portals/ delete 0.0.0.0 3260" >> ${CMDFILE}
#echo "portals/ create `hostname -i` 3260" >> ${CMDFILE}
# REMOVED ABOVE AND ADDING THE INTERFACE WHICH IS BONDED
echo "portals/ create 172.16.10.18 3260" >> ${CMDFILE}

# DEFINE ACCESS RIGHTS
echo "cd acls" >> ${CMDFILE}
for INITIQN in $IQNS
do
  echo "create ${INITIQN}" >> ${CMDFILE}
#
#  echo "${INITIQN}/ set auth userid=iuser password=ipass mutual_userid=mutuser mutual_password=mutpass" >> ${CMDFILE}
done

echo "cd /" >> ${CMDFILE}
echo "saveconfig" >> ${CMDFILE}
echo "exit" >> ${CMDFILE}
}  # END OF map_devs()

for VG in $VGS
do
  echo "# VG = $VG"
  TARGET_VG=$VG
  map_devs
  targetcli < ${TARGET}.cmd
done
