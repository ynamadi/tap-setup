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

Make sure [Cluster Essentials for VMware Tanzu is deployed to your cluster](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.3/cluster-essentials/GUID-deploy.html).

You don't need to use the `tanzu` CLI to apply the configuration with a GitOps approach:
all `tanzu` commands described in the documentation have been integrated as YAML definitions.

### Creating AWS Resources

####Step 1 - Create an EKS Cluster

```shell
export EKS_CLUSTER_NAME=tap-on-aws
export AWS_REGION="your-preferred-region"
eksctl create cluster --name $EKS_CLUSTER_NAME --managed --region $AWS_REGION --instance-types t3.large --version 1.23 --with-oidc -N 6
aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
```

####Step 2 - Create ECR container registries
```shell
aws ecr create-repository --repository-name tap-images --region $AWS_REGION
aws ecr create-repository --repository-name tap-build-service --region $AWS_REGION
```

With AWS ECR's limitation on creating repositories on push you will need to create a repo for each workload.
```shell
aws ecr create-repository --repository-name tanzu-application-platform/$WORKLOAD_NAME-$DEVELOPER_NAMESPACE --region $AWS_REGION
aws ecr create-repository --repository-name tanzu-application-platform/$WORKLOAD_NAME-$DEVELOPER_NAMESPACE-bundle --region $AWS_REGION
```

####Step 3 - If you are using k8s 1.23 and above you will need to enable the Amazon EBS CSI plugin.
```shell
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $EKS_CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

####Step 4 -  Remove **config-proxy** and **post-install** scripts from the initial installation.
**Note:** 
- _In **gitops/tap-install.yml** remove **- config-proxy** , **- post-install** , **scan_policies** and **tekton_pipelines** from template.ytt.paths and push to github._ 
- _During the installation there is a pre-check that happens for Contour resources in order to apply the proxy configuration, since contour is not available yet, we will need to wait for it to be installed before we can apply the proxy configurations._
- _Also this ensures the Scanners(Carbon-Black, Snyk or Grype), and Tekton are installed prior to creating objects_


####Step 5 - Create new file `tap-install-config.yml` in `gitops`, reusing content from [`tap-install-config.yml.tpl`](gitops/tap-install-config.yml.tmp).

Edit this file accordingly:

_In your gitops folder create tap-install-config.yml file with the following content below:_
```yaml
#@ load("@ytt:yaml", "yaml")
---
#@ def config():
tap:
  #! Set Backstage catalogs to include by default.
  catalogs:
  - https://github.com/tanzu-corp/tap-catalog/blob/main/catalog-info.yaml

  registry:
    host: ${REGISTRY_HOST}
    repositories:
      buildService: tanzu/tanzu-build-service
      ootbSupplyChain: tanzu/tanzu-supply-chain

  domains:
    main: tanzu.example.com
    tapGui: tap-gui.tanzu.example.com
    learningCenter: learningcenter.tanzu.example.com
    knative: apps.tanzu.example.com
    appliveview: appliveview.tanzu.example.com
    metadataStore: metadata-store.tanzu.example.com
  maven:
    url: ${ARTIFACTORY_URL}
#@ end
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tap-install-gitops
  namespace: tap-install-gitops
data:
  tap-config.yml: #@ yaml.encode(config())
```

####Step 3 - In your GitOps folder create tap-install-secrets.yml file with the following content below:
Edit this file accordingly:

_In your gitops folder create tap-install-secrets.yml file with the following content below:_

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
      username: ${REGISTRY_USERNAME}
      password: ${REGISTRY_PASSWORD}
    #! Remove suffix "-disabled" to enable GitHub integration:
    #! - set clientId and clientSecret to enable authentication,
    #! - set token to download resources from GitHub (such as Backstage catalogs).
    github:
      username: ${GITHUB_USERNAME}
      clientId: ${GITHUB_APP_CLIENT_ID}
      clientSecret: ${GITHUB_APP_CLIENT_SECRET}
      token: ${GITHUB_ACCESS_TOKEN}

    snyk:
      token: ${SNYK_ACCESS_TOKEN}

    customize:
      custom_logo: ${BASE64_LOGO}
      custom_name: ${COMPANY_NAME}
      org_name: ${ORG_NAME}

    certificate:
      tls.crt: ${BASE64_CERT}
      tls.key: ${BASE64_KEY}

    metadataStore:
      accessToken: "Bearer ${METADATA_ACCESS_TOKEN}"
    #! Remove suffix "-disabled" to enable Backstage persistence.
    backstage-disabled:
      database:
        client: pg
        host: INSERT-DB-HOST
        port: 5432
        username: INSERT-DB-USERNAME
        password: INSERT-DB-PASSWORD
#@ end
---
apiVersion: v1
kind: Secret
metadata:
  name: tap-install-gitops-github
  namespace: tap-install-gitops
stringData:
  username: github
  password: ${GITHUB_ACCESS_TOKEN}
---
apiVersion: v1
kind: Secret
metadata:
  name: tap-install-gitops
  namespace: tap-install-gitops
stringData:
  tap-secrets.yml: #@ yaml.encode(config())
```

####Step 4 - Deploy the kapp Application
```shell
kapp deploy -a tap-install-gitops -f <(ytt -f gitops)
```

####Step 5 - Check to make sure the Tanzu packages have started Reconciling. 
```shell
tanzu package installed list -n tap-install
```

####Step 6 - Add **config-proxy** and **post-install** scripts to gitops/tap-install.yml
**Note:**
- _Navigate to **gitops/tap-install.yml** add **- config-proxy** and **- post-install** to template.ytt.paths and push to github._

```yaml
  template:
  - ytt:
      paths:
      - config
      - config-full
      - config-proxy
      - post-install
```

####Step 7 - ReDeploy the kapp Application
```shell
kapp deploy -a tap-install-gitops -f <(ytt -f gitops)
```

####Step 8 - Retrieve Metadata Store Access Token and update gitops/tap-install-secrets.yml
```shell
export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets -n metadata-store -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='metadata-store-read-client')].data.token}" | base64 -d)
```

Example:
```yaml
metadataStore:
      accessToken: "Bearer ${METADATA_STORE_ACCESS_TOKEN}"
```


####Step 9 - Retrieve External IP Address and Update your DNS
```shell
kubectl get service envoy -n tanzu-system-ingress
```

As a part of the Out-Of-The-Box Supply Chain with Testing and Scanning you will need to create a ScanPolicy object in the developer namespace. The ScanPolicy defines a set of rules to evaluate for a particular scan to consider the artifacts (image or source code) either compliant or not 


For more information visit [ScanPolicy](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.2/tap/GUID-scc-ootb-supply-chain-testing-scanning.html#scan-policy)