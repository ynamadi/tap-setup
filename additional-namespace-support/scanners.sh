tanzu package install grype-scanner-prod --package-name grype.scanning.apps.tanzu.vmware.com --version 1.2.2 --namespace tap-install --values-file grype-values.yaml
tanzu package install snyk-scanner-prod --package-name snyk.scanning.apps.tanzu.vmware.com --version 1.0.0-beta.2 --namespace tap-install --values-file snyk-values.yaml
