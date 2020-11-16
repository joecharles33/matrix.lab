# Using Webhooks
For this example, I will be updating the HTML code for my website
https://www.linuxrevolution.com https://github.com/cloudxabide/www_linuxrevolution_com

## Github
I have little/no interest in doing this anywhere other than Github at this time.  So, I'll start with that.

### Retrive the a Secret (Openshift)
```
oc get bc wwwlinuxrevolutioncom -o jsonpath='{ .spec.triggers[?(@.type=="GitHub")].github.secret }'
```

### Retrieve the Webhook Payload URL
This is an absolute travesty of a method to this value, but works...
```
oc describe bc | egrep github | grep -v ^URL
```

## References
https://docs.openshift.com/container-platform/4.6/builds/triggering-builds-build-hooks.html
