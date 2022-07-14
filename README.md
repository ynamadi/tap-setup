# Deploying Tanzu Application Platform with GitOps

This project shows how to deploy
[Tanzu Application Platform](https://tanzu.vmware.com/application-platform) (TAP)
with a GitOps approach. Using this strategy, you can share the same configuration
across different installations
(one commit means one `tanzu package installed update` for every cluster),
while tracking any configuration updates with Git (easy rollbacks).

**Please note that this project is authored by a VMware employee under open source license terms.**

## How does it work?

You don't need to deploy any additional components to your cluster.
This GitOps approach relies on [kapp-controller](https://carvel.dev/kapp-controller/)
and [ytt](https://carvel.dev/ytt/) to track Git commits and apply the configuration
to every cluster. These tools are part of the TAP prerequisites.

## How to use it?

Make sure [Cluster Essentials for VMware Tanzu is deployed to your cluster](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#install-cluster-essentials-for-vmware-tanzu-2).

You don't need to use the `tanzu` CLI to apply the configuration with a GitOps approach:
all `tanzu` commands described in the documentation have been integrated as YAML definitions.

Create new file `tap-install-config.yml` in `gitops`, reusing content from [`tap-install-config.yml.tpl`](gitops/tap-install-config.yml).
Edit this file accordingly:

In your gitops folder create tap-install-config.yml file with the following content below:

````yaml
#@ load("@ytt:yaml", "yaml")
---
#@ def config():
tap:
  #! Set Backstage catalogs to include by default.
  catalogs:
  - https://github.com/tanzu-corp/tap-catalog/blob/main/catalog-info.yaml

  #! Replace ${REGISTRY_HOST} with your container registry host.
  registry:
    host: ${REGISTRY_HOST}
    repositories:
      buildService: tanzu/tanzu-build-service
      ootbSupplyChain: tanzu/tanzu-supply-chain

  #! Replace example.com with your domain.
  domains:
    main: apps.example.com
    tapGui: tap-gui.apps.example.com
    learningCenter: learningcenter.apps.example.com
    knative: apps.example.com
#@ end
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tap-install-gitops
  namespace: tap-install-gitops
data:
  tap-config.yml: #@ yaml.encode(config())
````

In your gitops folder create tap-install-secrets.yml file with the following content below:
```yaml
#@ load("@ytt:yaml", "yaml")
---
#@ def config():
tap:
  credentials:
    #! Pick one registry for downloading images: Tanzu Network or Pivotal Network
    #! (use tanzuNet as key).
    tanzuNet:
      username: ${TANZUNET_USERNAME}
      password: ${TANZUNET_PASSWORD}

    registry:
      username: ${CONTAINER_REGISTRY_USERNAME}
      password: ${CONTAINER_REGISTRY_PASSWORD}
    #! Remove suffix "-disabled" to enable GitHub integration:
    #! - set clientId and clientSecret to enable authentication,
    #! - set token to download resources from GitHub (such as Backstage catalogs).
    github:
      clientId: ${GITHUB_OAUTH_APP_CLIENT_ID}
      clientSecret: ${GITHUB_OAUTH_APP_CLIENT_SECRET}
      token: ${GITHUB_AUTH_TOKEN}

    certificate:
      tls.crt: ${BASE64_ENCODED_CERT}
      tls.key: ${BASE64_ENCODED_KEY}

    metadataStore:
      accessToken: "Bearer ${METADATA_STORE_ACCESS_TOKEN}"
    #! Remove suffix "-disabled" to enable Backstage persistence.
    backstage-disabled:
      database:
        client: pg
        host: ${DB_HOST}
        port: ${DB_PORT}
        username: ${DB_USERNAME}
        password: ${DB_PASSWORD}
#@ end
---
apiVersion: v1
kind: Secret
metadata:
  name: tap-install-gitops-github
  namespace: tap-install-gitops
stringData:
  username: github
  password: ${GITHUB_AUTH_TOKEN}
---
apiVersion: v1
kind: Secret
metadata:
  name: tap-install-gitops
  namespace: tap-install-gitops
stringData:
  tap-secrets.yml: #@ yaml.encode(config())
```

For the initial installation we need to remove - config-proxy from gitops/tap-install.yml file. 

During the installation there is a pre-check that happens for Contour resources in order to apply the proxy configuration, since contour is not available yet, we will need to wait for it to be installed before we can apply the proxy configurations.




# tap-setup
Full installation for Tanzu Application Platform

```shell
kapp deploy -a tap-install-gitops -f <(ytt -f gitops)

kubectl get svc -n tanzu-system-ingress
```

As a part of the Out-Of-The-Box Supply Chain with Testing and Scanning you will need to create a ScanPolicy object in the developer namespace. The ScanPolicy defines a set of rules to evaluate for a particular scan to consider the artifacts (image or source code) either compliant or not 


For more information visit [ScanPolicy](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.2/tap/GUID-scc-ootb-supply-chain-testing-scanning.html#scan-policy)


Apply Scan policy that will be used for source and image scanning: 

```shell
kubectl create -f ootb_testing_scanning/scan-policy.yaml
```


```shell
export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets -n metadata-store -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='metadata-store-read-client')].data.token}" | base64 -d)
```