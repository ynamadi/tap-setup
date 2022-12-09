#! /bin/bash
export EKS_CLUSTER_NAME=tap-full
export AWS_REGION="us-east-2"
export AWS_ACCOUNT_ID="030072716919"

eksctl delete cluster -n $EKS_CLUSTER_NAME -r $AWS_REGION

aws ecr delete-repository --repository-name tap-images --region $AWS_REGION --force
aws ecr delete-repository --repository-name tap-build-service --region $AWS_REGION --force
aws ecr delete-repository --repository-name tanzu-application-platform/tanzu-java-web-app-tap-dev --region $AWS_REGION --force
aws ecr delete-repository --repository-name tanzu-application-platform/tanzu-java-web-app-tap-dev-bundle --region $AWS_REGION --force

aws iam delete-role-policy --role-name tap-build-service --policy-name tapBuildServicePolicy
aws iam delete-role --role-name tap-build-service

aws iam delete-role-policy --role-name tap-workload --policy-name tapWorkload
aws iam delete-role --role-name tap-workload