#! /bin/bash
export EKS_CLUSTER_NAME=aws-eks-us-east2
export AWS_REGION="us-east-1"

eksctl delete cluster --region=$AWS_REGION --name=$EKS_CLUSTER_NAME