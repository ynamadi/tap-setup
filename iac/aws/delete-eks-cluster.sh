#! /bin/bash
export EKS_CLUSTER_NAME=tap-full
export AWS_REGION="us-west-1"

eksctl delete cluster --region=$AWS_REGION --name=$EKS_CLUSTER_NAME