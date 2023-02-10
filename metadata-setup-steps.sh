nslookup metadata-store.tap.tanzu.y-compiles.com
curl https://metadata-store.tap.tanzu.y-compiles.com/api/health -k -v

kubectl get secret ingress-cert -n metadata-store -o json | jq -r '.data."ca.crt"' | base64 -d > insight-ca.crt
tanzu insight config set-target https://metadata-store.tap.tanzu.y-compiles.com --ca-cert insight-ca.crt
tanzu insight health
#To retrieve the read-only access token, run the following command:
export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d)
echo "$METADATA_STORE_ACCESS_TOKEN"