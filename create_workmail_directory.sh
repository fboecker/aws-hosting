#!/bin/bash
export AWS_REGION=eu-west-1

echo 'Enter your AWS ACCESS KEY ID(i.e. AKKSSKSKSKKDKDKDLDFK):'
read awskey
export AWS_ACCESS_KEY_ID=$awskey

echo 'Enter your AWS SECRET ACCESS KEY(i.e. xysvbasudqwbdbdasWWdSdSS/233sdwidwidi323nd9):'
read awssecret
export AWS_SECRET_ACCESS_KEY=$awssecret


echo "select VPC name"...
$(aws --region $AWS_REGION ec2 describe-vpcs --query "Vpcs[?isDefault == true].[VpcId]" --output text > tmpFile)
VPC_NAME=$(<tmpFile)
rm -f tmpFile
echo "VPC name $VPC_NAME"

echo "select subnet1"
$(aws --region $AWS_REGION ec2 describe-subnets --query "Subnets[?VpcId == '$VPC_NAME'] | [0].[SubnetId]" --output text > tmpFile)
SUBNET_1=$(<tmpFile)
rm -f tmpFile
echo "Subnet-1: $SUBNET_1"

echo "select subnet2"
$(aws --region $AWS_REGION ec2 describe-subnets --query "Subnets[?VpcId == '$VPC_NAME'] | [1].[SubnetId]" --output text > tmpFile)
SUBNET_2=$(<tmpFile)
rm -f tmpFile
echo "Subnet-1: $SUBNET_2"

echo "create simple directory..."
$(aws --region "$AWS_REGION" cloudformation deploy --stack-name webhosting-4--workemail --template-file cloudformation-scripts/4_create_simpledirectory_and_email.yml --parameter-overrides VpcID=$VPC_NAME SubnetOne=$SUBNET_1 SubnetTwo=$SUBNET_2 ) 



echo "please create the Workmail organization manually"

echo "End..."
