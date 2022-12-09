export CVE_ID="CVE-2016-1000027"
export IMAGE_DIGEST="sha256:acd4fdba1a6fdbe1302bda593f254f71a357ac5028b0170a0abbf42f8df801b2"
export METADATA_STORE_ACCESS_TOKEN
METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d)

tanzu insight image get --digest $IMAGE_DIGEST
#Get image packages
tanzu insight image packages --digest $IMAGE_DIGEST

#Get image vulnerabilities
tanzu insight image vulnerabilities --digest $IMAGE_DIGEST

#Get vulnerability by CVE id
tanzu insight vulnerabilities get --cveid $CVE_ID

#List all the images with the following CVE's
tanzu insight vulnerabilities images --cveid $CVE_ID


#List of all packages impacted by the CVE
tanzu insight vulnerabilities packages --cveid $CVE_ID

tanzu insight package get --name base-passwd --version 3.5.44 --pkgmngr Unknown
tanzu insight package images --name base-passwd