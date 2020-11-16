# VMware-Customization.md

## OCP4 on VMware (vSphere 6.7) Custom to add second NIC
Create the manifests
```
[root@rh7-lms-srv01 OCP4]# ./openshift-install create manifests --dir=${OCP4DIR}
? SSH Public Key /root/.ssh/id_rsa.pub
? Platform vsphere
? vCenter vmw-vcenter6.matrix.lab
? Username administrator@vsphere.matrix.lab
? Password [? for help] *********
INFO Connecting to vCenter vmw-vcenter6.matrix.lab
INFO Defaulting to only available datacenter: HomeLab
INFO Defaulting to only available cluster: OCP4-StandAlone
? Default Datastore datastore-shared-iscsi
? Network DPortGroup-Guests
? Virtual IP Address for API 10.10.10.161
? Virtual IP Address for Ingress 10.10.10.162
? Base Domain linuxrevolution.com
? Cluster Name ocp4-mwn
? Pull Secret [? for help] *******
```

### Update Manifests to include the creation of the second NIC
```
cd ${OCP4DIR}/manifests

cat << EOF > cluster-network-03-addnic.yml
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  defaultNetwork:
    type: OpenShiftSDN
    openshiftSDNConfig:
      mode: NetworkPolicy
      mtu: 1450
EOF
```

```
[root@rh7-lms-srv01 manifests]# ls -l | grep cluster-network
-rw-r-----. 1 root root  513 Oct 16 15:31 cluster-network-01-crd.yml
-rw-r-----. 1 root root  272 Oct 16 15:31 cluster-network-02-config.yml
```
