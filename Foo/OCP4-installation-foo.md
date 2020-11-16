# OCP4 Installation Foo
STATUS:  Work in Progress.  Trying to make this less dependent on the host it's running on and PULL 
           everything needed for all the tasks.

```
THEDATE=`date +%F-%H%M`
OCP4DIR=${HOME}/OCP4/${CLUSTER_NAME}.${BASE_DOMAIN}-${THEDATE}
```
 
## Download the Installer and Client
```
# TODO: instead of doing an rm, figure out how to rename it based on the version or something
FILES="openshift-install-linux.tar.gz openshift-client-linux.tar.gz"
for FILE in $FILES
do 
  mv $FILE $FILE-$THEDATE
done

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz

for FILE in openshift-install-linux.tar.gz openshift-client-linux.tar.gz; do tar -xvzf $FILE; done
```

## Install the certs from VMware vCenter
```
wget --no-check-certificate https://vmw-vcenter6.matrix.lab/certs/download.zip
unzip download.zip -d $OCP4DIR/
cp  $OCP4DIR/certs/lin/*.0 /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
```

## Getting Started
```
cd ${HOME}/OCP4/
tmux new -s OCP4install || tmux attach -t OCP4install

CLUSTER_NAME=ocp4-mwn
BASE_DOMAIN=linuxrevolution.com
#BASE_DOMAIN=matrix.lab
nslookup api.${CLUSTER_NAME}.${BASE_DOMAIN}
nslookup *.apps.${CLUSTER_NAME}.${BASE_DOMAIN}

eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa
sed -i -e '/^10.10/d' ~/.ssh/known_hosts
THEDATE=`date +%F-%H%M`; OCP4DIR=${CLUSTER_NAME}.${BASE_DOMAIN}-${THEDATE}; mkdir $OCP4DIR

# The following creates the "install-config" - copy it out of the directory
#./openshift-install create install-config --dir=${OCP4DIR}/ --log-level=info
# Using the previously created install config....
cp install-config-vsphere-${CLUSTER_NAME}.${BASE_DOMAIN}.yaml $OCP4DIR/install-config.yaml
./openshift-install create cluster --dir=${OCP4DIR}/ --log-level=debug
#export KUBECONFIG=${OCP4DIR}/auth/kubeconfig
```

If you'd like to create an install configuration, or already have an existing install configuration:
```
cp install-config-vsphere.yaml $OCP4DIR/install-config.yaml
```

## OCP4 on RHV (RHHI-V)
Status:  Untested.  I do not have an environment to test this with yet.

Datastore: vmstore
Cluster Name: Default

```
curl -k -u admin@internal:NotAPassword https://rh7-rhv4-mgr01.matrix.lab/ovirt-engine/api
dig api.ocp4-mwn.matrix.lab
dig test.apps.ocp4-mwn.matrix.lab
dig *.apps.ocp4-mwn.matrix.lab | grep "^*"
curl -k 'https://rh7-rhv4-mgr01.matrix.lab/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA' -o /tmp/ca.pem
chmod 0644 /tmp/ca.pem
cp -p /tmp/ca.pem /etc/pki/ca-trust/source/anchors/ca-rh7-rhv4-mgr01.pem
update-ca-trust
```

I have a bit of an intersting situation - my HomeLab has it's own DNS (matrix.lab) but the exposed IP uses (linuxrevolution.com).  Therefore, I build my cluster using matrix.lab
- Values I used

```
? SSH Public Key /root/.ssh/id_rsa.pub
? Platform ovirt
? oVirt cluster Default
? oVirt storage domain vmstore
? oVirt network guest
? Internal API virtual IP 10.10.10.161
? Internal DNS virtual IP 10.10.10.163
? Ingress virtual IP 10.10.10.162
? Base Domain matrix.lab
? Cluster Name ocp4-mwn
? Pull Secret [? for help]
```

oc login -u kubeadmin -p `cat $(find $OCP4DIR/*mwn* -name kubeadmin-password)`  https://api.ocp4-mwn.matrix.lab:6443/

## Login to the Environment

```
export KUBECONFIG=/root/OCP4/${OCP4DIR}/auth/kubeconfig
oc get nodes
```

## Registry (NFS)
For *my* enviromment, NFS was the ideal target for the registry as it provides RWX as is ideal.
NOTE: it is assumed that OCP has been successfully installed by this time.
Also - I had to do some nonsense to make my freeNAS work for this (and it's likely NOT ideal)

### Create the yaml definition for the registry PV and PVC
```
mkdir ${OCP4DIR}/Registry; cd $_
cat << EOF > image-registry-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: image-registry-pv
spec:
  accessModes:
    - ReadWriteMany
  capacity:
      storage: 100Gi
  nfs:
    path: /mnt/raidZ/nfs-registry
    server: 10.10.10.19
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-registry
EOF

cat << EOF > image-registry-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources: 
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  storageClassName: nfs-registry
EOF
```

### Create and Validate the PV/PVC
```
kubectl apply -f image-registry-pv.yaml
kubectl -n openshift-image-registry apply -f image-registry-pvc.yaml
kubectl -n openshift-image-registry get pvc
```

### Update the ImageRegistry Operator Config 
TL;DR: update  
```
managementState: Removed
managementState: Managed
```

```
strorage: {}
storage:  
  pvc:  
    claim: image-registry-pvc
```

NOTE:  you are editing the lower section of the config once it's opened
```
oc edit configs.imageregistry.operator.openshift.io -o yaml
## Apply the changes (above) and close the file
oc get clusteroperator image-registry
while true; do oc get clusteroperator image-registry; sleep 2; done
```

### Increase the worker node capacity, if necessary:
```
oc edit machineset -n openshift-machine-api

          memoryMiB: 8192
          numCPUs: 2
          numCoresPerSocket: 1

          memoryMiB: 12288 
          numCPUs: 2
          numCoresPerSocket: 2
```

## Customize the OpenShift Console logo

```
wget https://github.com/cloudxabide/matrix.lab/raw/master/images/LinuxRevolution_RedGradient.png -O ${OCP4DIR}/LinuxRevolution_RedGradient.png
oc create configmap console-custom-logo --from-file ${OCP4DIR}/LinuxRevolution_RedGradient.png  -n openshift-config
oc edit console.operator.openshift.io cluster
# Update spec: customization: customLogoFile: {key,name}:
  customization:
    customLogoFile:
      key: LinuxRevolution_RedGradient.png
      name: console-custom-logo
    customProductName: LinuxRevolution Console
```

## Add htpasswd 
```
wget https://raw.githubusercontent.com/cloudxabide/matrix.lab/master/Files/ocp4-idp-htpasswd -O ${OCP4DIR}/ocp4-idp-htpasswd
oc create secret generic htpass-secret --from-file=htpasswd=${OCP4DIR}/ocp4-idp-htpasswd  -n openshift-config
cat << EOF > ${OCP4DIR}/HTPasswd-CR
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

oc apply -f ${OCP4DIR}/HTPasswd-CR
```

## Add Legit Certs
review [LetsEncrypt-HowTo](./lets_encrypt.md)  
NOTE:  This *should* be done with CertManager.

## References
https://www.virtuallyghetto.com/2020/07/using-the-new-installation-method-for-deploying-openshift-4-5-on-vmware-cloud-on-aws.html
https://docs.openshift.com/container-platform/4.6/web_console/customizing-the-web-console.html

### Custom Machinesets during IPI install
https://github.com/openshift/installer/blob/master/docs/user/customization.md
https://github.com/openshift/installer/blob/master/docs/user/vsphere/customization.md#machine-pools

## Random foo
```
for IP in `oc get nodes -o wide | awk '{ print $6 }' | grep -v INT`; do ssh core@${IP} "grep proc /proc/cpuinfo"; done
for IP in `oc get nodes -o wide | awk '{ print $6 }' | grep -v INT`; do ssh core@${IP} "uptime"; done
```

```
oc get pods --all-namespaces | egrep -v 'Running' | awk '{ print "oc delete pod " $2 " -n " $1 }' > /tmp/blah
sh /tmp/blah
```
### Clean up between cluster deploys
```
ssh seraph.matrix.lab
rm -rf /mnt/raidZ/nfs-registry/docker
```

```
export KUBECONFIG=$(find ~/OCP4/*acm* -name kubeconfig)
cat $(find ~/OCP4/*acm* -name kubeadmin-password)
oc login -u kubeadmin -p `cat $(find ${HOME}/OCP4/*acm* -name kubeadmin-password)`  https://api.ocp4-acm.matrix.lab:6443/

export KUBECONFIG=$(find ~/OCP4/*mwn* -name kubeconfig)
cat $(find ~/OCP4/*mwn* -name kubeadmin-password)
oc login -u kubeadmin -p `cat $(find ${HOME}/OCP4/*mwn* -name kubeadmin-password)`  https://api.ocp4-mwn.matrix.lab:6443/


