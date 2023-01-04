export METADATA_STORE_URL="metadata-store.tap.tanzu.y-compiles.com"
nslookup $METADATA_STORE_URL
curl "https://${METADATA_STORE_URL}/api/health" -k -v

kubectl get secret ingress-cert -n metadata-store -o json | jq -r '.data."ca.crt"' | base64 -d > insight-ca.crt
tanzu insight config set-target "https://${METADATA_STORE_URL}" --ca-cert insight-ca.crt
tanzu insight health
#To retrieve the read-only access token, run the following command:
export METADATA_STORE_ACCESS_TOKEN
METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d)

echo "$METADATA_STORE_ACCESS_TOKEN"