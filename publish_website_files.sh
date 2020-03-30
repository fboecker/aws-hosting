#!/bin/bash
export AWS_REGION=eu-west-1
export AWS_REGION_US=us-east-1

echo 'Enter your AWS ACCESS KEY ID(i.e. AKKSSKSKSKKDEXAMPLE):'
read awskey
export AWS_ACCESS_KEY_ID=$awskey

echo 'Enter your AWS SECRET ACCESS KEY(i.e. xysvbasudqwbdbdasWWdSdSS/233sdwidwidi323nd9):'
read awssecret
export AWS_SECRET_ACCESS_KEY=$awssecret

echo select domain name...
$(aws --region $AWS_REGION_US cloudformation list-exports --query "Exports[?Name=='DomainName'].[Value]" --output text > tmpFile)
DOMAIN_NAME=$(<tmpFile) 
rm -fv tmpFile
echo domainname $DOMAIN_NAME

echo copy HTML files to S3
aws s3 cp website/ s3://www.$DOMAIN_NAME --recursive

echo your HTML files were copied
