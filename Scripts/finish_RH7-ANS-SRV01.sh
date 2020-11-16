#!/bin/bash

PWD=`pwd`
DATE=`date +%Y%m%d`
ARCH=`uname -p`
YUM=$(which yum)

if [ `/bin/whoami` != "root" ]
then
  echo "ERROR:  You should be root to run this..."
  exit 9
fi

# Subscribe and update Host
subscription-manager register --auto-attach 
subscription-manager repos --disable="*" --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms
shutdown now -r


# Let's do this... Install Tower
[ -f ansible-tower-setup-latest.tar.gz ] && mv ansible-tower-setup-latest.tar.gz ansible-tower-setup-latest.tar.gz-`stat ansible-tower-setup-latest.tar.gz  | grep ^Modify | awk '{ print $2 }'`

wget https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz
tar -xvzf ansible-tower-setup-latest.tar.gz
cd $(find . -type d -name "ansible-tower-setup*")

# Create inventory file
cat << EOF > ${HOME}/tower_inventory.yaml
[tower]
localhost ansible_connection=local

[database]

[all:vars]
admin_password='NotAPassword'

pg_host=''
pg_port=''

pg_database='tower'
pg_username='tower'
pg_password='NotAPassword'
EOF

./setup.sh -i ${HOME}/tower_inventory.yaml

## Foo
### Change Password
awx-manage changepassword admin
