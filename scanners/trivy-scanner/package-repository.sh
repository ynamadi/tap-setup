---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: trivy-scanner-repository
  namespace: tap-install
spec:
  fetch:
    imgpkgBundle:
      image: projects.registry.vmware.com/tanzu_practice/tap-scanners-package/trivy-repo-scanning-bundle:0.1.4-alpha.6