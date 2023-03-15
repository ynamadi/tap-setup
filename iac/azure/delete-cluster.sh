#! /bin/bash
export AKS_RESOURCE_GROUP="tap-full-rg"
export AKS_CLUSTER_NAME="tap-full"

az aks delete --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --yes