# ACM Installation Foo

## Objective
Provide details/notes of the ACM installation process.

## Status
**WIP:** this is most definitely a Work In-Progress at this point.  ACM is being improved fairly regularly and I 
will be expanding what resources I manage with it.

## Prereqs
You should have already built a cluster (and therefore downloaded the clients, certs from VMware, etc...

## Getting Started
```
THEDATE=`date +%F-%H%M`
ENV=ACMinstall
cd ${HOME}/OCP4/
tmux new -s $ENV || tmux attach -t $ENV 

CLUSTER_NAME=ocp4-acm
BASE_DOMAIN=linuxrevolution.com
nslookup api.${CLUSTER_NAME}.${BASE_DOMAIN}
nslookup *.apps.${CLUSTER_NAME}.${BASE_DOMAIN}

eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa
sed -i -e '/^10.10/d' ~/.ssh/known_hosts
THEDATE=`date +%F-%H%M`; OCP4DIR=${CLUSTER_NAME}.${BASE_DOMAIN}-${THEDATE}; mkdir $OCP4DIR

# Using a previously created install config....
cp install-config-vsphere-${CLUSTER_NAME}.${BASE_DOMAIN}.yaml $OCP4DIR/install-config.yaml
./openshift-install create cluster --dir=${OCP4DIR}/ --log-level=debug
```

If you'd like to create an install configuration, or already have an existing install configuration:
```
cp install-config-vsphere.yaml $OCP4DIR/install-config.yaml
```
## Login to the Environment

```
export KUBECONFIG=/root/OCP4/${OCP4DIR}/auth/kubeconfig
oc get nodes
```

or
```
oc login -u kubeadmin -p `cat $(find $OCP4DIR/*acm* -name kubeadmin-password)`  https://api.ocp4-acm.matrix.lab:6443/
```

## Registry (NFS)
For *my* enviromment, NFS was the ideal target for the registry as it provides RWX, as is req'd
NOTE: it is assumed that OCP has been successfully installed by this time.
Also - I had to do some nonsense to make my freeNAS work for this (and it's likely NOT ideal)

### Create the yaml definition for the registry PV and PVC
```
mkdir ${OCP4DIR}/Registry; cd $_
cat << EOF > acm-image-registry-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: acm-image-registry-pv
spec:
  accessModes:
    - ReadWriteMany
  capacity:
      storage: 100Gi
  nfs:
    path: /mnt/raidZ/nfs-registry-acm
    server: 10.10.10.19
  persistentVolumeReclaimPolicy: Retain
  storageClassName: acm-nfs-std 
EOF

cat << EOF > acm-image-registry-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: acm-image-registry-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources: 
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  storageClassName: acm-nfs-std 
EOF
```

### Create and Validate the PV/PVC
```
kubectl apply -f acm-image-registry-pv.yaml
kubectl -n openshift-image-registry apply -f acm-image-registry-pvc.yaml
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

### Increase the worker node capacity 
ACM seemed to demand more resources than what the worker nodes of a"standard" deployment (3 x 2vCPU, 8GB mem) would offer>

It's likely best to create a new machineset for the ACM worker nodes.  But, since my entire cluster is dedicated to ACM, I went with this route.

Update your machineset from the top values to the lower ones.
```
MACHINESET=$(oc get machineset -n openshift-machine-api | grep -v ^NAME | awk '{ print $1 }')
oc edit machineset $MACHINESET -n openshift-machine-api

          memoryMiB: 8192
          numCPUs: 2
          numCoresPerSocket: 1

          memoryMiB: 12288 
          numCPUs: 2
          numCoresPerSocket: 2

oc scale --replicas=0 machineset $MACHINESET
oc scale --replicas=3 machineset $MACHINESET
```

## Update the Logo
wget https://github.com/cloudxabide/matrix.lab/raw/master/images/AdvClusterMGMT_BlueGradient.png
oc create configmap console-custom-logo --from-file AdvClusterMGMT_BlueGradient.png  -n openshift-config
oc edit console.operator.openshift.io cluster
# Update spec: customization: customLogoFile: {key,name}:
  customization:
    customLogoFile:
      key: AdvClusterMGMT_BlueGradient.png
      name: console-custom-logo
    customProductName: RHACM OCP4 Console
