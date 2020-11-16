# Lets Encrypt Certificates

Status:   Work in Progress (2020-10-29)
Purpose:  To detail what is necessary to utilize LetsEncrypt certs in your 
          cluster.  Additionally, I may try to figure out where the certs you
          provide in your inventory, actually end up on the filesystem.
Credit:   Please see the references at the bottom of this doc.  A fellow Red Hatter (Karan Singh) wrote a great article.


## Overview
My environment is a home lab which has a single ingress/egress point and a single IP.  I also have a domain (linuxrevolution.com) with DNS provided by route53.  Generally OpenShift has a tertiary domain provided - "cloudapps" is usually referenced - in my case it is "ocp4-mwn" (ocp4-mwn.linuxrevolution.com).  My tertiary domain is also handled by route53.

## The process
I'm not going to provide details on how to install RHEL, nor LetsEncrypt - mostly because there are *plenty* of docs out there, and the moment I run "git push" my docs will probably be out of date.  

Create your top-level domain (TLD) in AWS Route53 (and ONLY your TLD).  This actually took me a bit to figure out, as it is NOT intuitive.  You start with your TLD with no reference to OCP.  Then create your certs (which creates a bunch of entries (TXT records) and then removes them.  Once complete, you will need to then create your 2 x A records (api.<cluster_name>.<domain> and *.apps.<cluster_name>.<domain>).  NOTE:  You *can* create subdomains from your TLD, but it's a bit of a PITA (and not worth it, IMO, since we only need 2 static IP entries).

## LetsEncrypt using AWS CLI
NOTE:  This is NOT my stuff (acme.sh) - use with caution
Update your $HOME/.aws/credentials file with your Route53 enabled user

```
cd $HOME
git clone https://github.com/acmesh-official/acme.sh.git
cd acme.sh
AWS_ACCESS_KEY_ID=$(grep -a2 $AWS_USER ~/.aws/credentials | grep aws_access_key_id | awk -F\= '{ print $2 }' | sed 's/ //g')
AWS_SECRET_ACCESS_KEY=$(grep -a2 $AWS_USER ~/.aws/credentials | grep aws_secret_access_key | awk -F\= '{ print $2 }' | sed 's/ //g')
export AWS_ACCESS_KEY_ID  AWS_SECRET_ACCESS_KEY
echo $AWS_ACCESS_KEY_ID
[ -z $AWS_SECRET_ACCESS_KEY ] && echo "hol'up - you did not set your AWSCLI vars yet"

export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
export LE_TLD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}' | awk -F\. '{print $(NF-1)"." $NF}')
echo "Top Level Domain: $LE_TLD"
echo "API Endpoint: $LE_API"
echo "Apps Wildcard: $LE_WILDCARD"

issue_new_cert() {
echo "${HOME}/acme.sh/acme.sh --issue -d ${LE_API} -d *.${LE_WILDCARD} -d *.${LE_TLD} --dns dns_aws"
${HOME}/acme.sh/acme.sh --issue -d ${LE_API} -d *.${LE_WILDCARD} -d *.${LE_TLD} --dns dns_aws
}

export CERTDIR=$HOME/certificates
mkdir -p ${CERTDIR}
${HOME}/acme.sh/acme.sh --install-cert -d ${LE_API} -d *.${LE_WILDCARD} -d *.${LE_TLD} --cert-file ${CERTDIR}/cert.pem --key-file ${CERTDIR}/key.pem --fullchain-file ${CERTDIR}/fullchain.pem --ca-file ${CERTDIR}/ca.cer

oc create secret tls router-certs --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/key.pem -n openshift-ingress
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'

# WARNING - this has limited testing at this point.
oc create secret tls api-certs --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/key.pem -n openshift-config
oc patch apiserver cluster --type=merge --patch='{"spec": { "servingCerts": {"namedCertificates": [{"names": ["api.ocp4-mwn.linuxrevolution.com"], "servingCertificate": {"name": "api-certs" }}]}}}'

# Cleanup (start over)
oc delete secret lts router-certs -n openshift-ingress
```

###
https://medium.com/@karansingh010/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875


## Notes 
I had attempted to do all this by manually creating my certs, etc... thankfully the "automated" process (above) works instead ;-)  

* --from-file=/root/OCP4/Certs/chain1.pem  
* --cert=/root/OCP4/Certs/cert1.pem  
* --key=/root/OCP4/Certs/privkey1.pem  

You will get 4 files from LetsEncrypt in /etc/letsencrypt/archive 
cert1.pem <- certfile  
chain1.pem <- cafile  
fullchain1.pem <- I suspect not used, but.. it might be the cafile?
privkey1.pem <- keyfile  

Review the Certs
```
cd /root/OCP4/Certs
for FILE in `ls *2.pem`; do echo "## $FILE"; openssl x509 -in $FILE -noout -text ; done
```

## References
https://medium.com/@karansingh010/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875  

Don't use this one - but, it's good to review: 
https://docs.openshift.com/container-platform/4.5/security/certificates/replacing-default-ingress-certificate.html

