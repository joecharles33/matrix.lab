# Red Hat Advanced Cluster Management

There are 2 (or more?) methods to deploy Red Hat Advanced Cluster Management - CLI and webUI.  For now, I am going to use the webUI and the Operator Hub.

Browse to your OpenShift Cluster Console | Operators | OperatorHub
Click on Advanced Cluster Management for Kubernetes | Install 
I accept the defaults and click Install

You'll need to retrieve your "pull secret" from cloud.redhat.com
Create a new secret "acm-pull-secret"
Click on Installed Operators | Advanced Cluster Management for Kubernetes 
Click on MultiClusterHubs | Create MultiClusterHubs
Click on YAML View 
change
spec: {} 
to...
spec:
  imagePullSecret: acm-pull-secret



## References
[Red Hat Advanced Cluster Management for Kubernetes](https://www.redhat.com/en/technologies/management/advanced-cluster-management)  
[Red Hat OpenShift Blog - Topic Search: Advanced Cluster Management](https://www.openshift.com/blog/tag/red-hat-advanced-cluster-management)  
[Red Hat OpenShift Blog - How to get started with Red Hat Advanced Cluster Management](https://www.openshift.com/blog/how-to-get-started-with-red-hat-advanced-cluster-management-for-kubernetes)

### Video Content
[Red Hat OpenShift - YouTube - Welcome to Twitch, Star Wars Day, Red Hat Advanced Cluster Management and more](https://www.youtube.com/watch?v=HtoNtG-Of78) (May 17, 2020)  
[Red Hat OpenShift - YouTube - How to Install and get started with Red Hat Advanced Cluster Management for Kubernetes (ACM)](https://www.youtube.com/watch?v=6dLkYEBUNn0) Jun 30, 2020 - Jimmy Alvarez @REDHAT

### Twitch Shows
[RedHatOpenShift Twitch.tv - Landing Page](https://www.twitch.tv/redhatopenshift/video/611018716?filter=highlights&sort=time)  
[RedHatOpenShift Twitch.tv - Red Hat Advanced Cluster Management Presents…](https://www.twitch.tv/redhatopenshift/video/783547154)  
[RedHatOpenShift Twitch.tv - Red Hat Advanced Cluster Management Presents...](https://www.twitch.tv/redhatopenshift/video/769284844)  
[RedHatOpenShift Twitch.tv - Highlight: Red Hat Advanced Cluster Management for Kubernetes from the InfoSec side](https://www.twitch.tv/videos/611018716) May 4, 2020 - Erik Jacobs @REDHAT  
