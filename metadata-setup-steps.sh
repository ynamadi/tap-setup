nslookup metadata-store.tap.tanzu.projectscions.com
curl https://metadata-store.tanzu.tap.tanzu.projectscions.com/api/health -k -v

kubectl get secret ingress-cert -n metadata-store -o json | jq -r '.data."ca.crt"' | base64 -d > insight-ca.crt
tanzu insight config set-target https://metadata-store.tap.tanzu.projectscions.com --ca-cert insight-ca.crt
tanzu insight health
#To retrieve the read-only access token, run the following command:
export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets -n metadata-store -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='metadata-store-read-client')].data.token}" | base64 -d)