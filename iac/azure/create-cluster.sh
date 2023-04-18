#! /bin/bash
export AKS_RESOURCE_GROUP="tap-full-rg"
export AKS_CLUSTER_NAME="tap-full"
export AKS_CLUSTER_LOCATION="eastus2"
export AKS_CLUSTER_VERSION="1.25.6"

az group create -l ${AKS_CLUSTER_LOCATION} -n ${AKS_RESOURCE_GROUP}

az aks create \
 --resource-group ${AKS_RESOURCE_GROUP} \
 --name ${AKS_CLUSTER_NAME} \
 --node-count 5 \
 --generate-ssh-keys \
 --load-balancer-sku standard \
 --node-vm-size Standard_D4_v3 \
 --enable-addons monitoring \
 --kubernetes-version ${AKS_CLUSTER_VERSION}

az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME}

./cluster-essentials.sh