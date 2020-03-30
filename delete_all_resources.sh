#!/bin/bash
#
#    remove all AWS resources
#
#
export AWS_REGION_US=us-east-1
export AWS_REGION=eu-west-1

echo 'Enter your AWS ACCESS KEY ID(i.e. AKKSSKSKSKKDKDKDLDFK):'
read awskey
export AWS_ACCESS_KEY_ID=$awskey

echo 'Enter your AWS SECRET ACCESS KEY(i.e. xysvbasudqwbdbdasWWdSdSS/233sdwidwidi323nd9):'
read awssecret
export AWS_SECRET_ACCESS_KEY=$awssecret

echo 'Enter your Domain Name(i.e. domain.de):'
read domname
export DOMAIN_NAME=$domname

echo "your domain name is $DOMAIN_NAME! Is this correct?(y/n):"
read success

if [ $(tr "[:upper:]" "[:lower:]" <<< "$success") != "y" ];then echo 'jump to the end!' && exit ;fi


echo "select organization..."
$(aws --region "$AWS_REGION" workmail list-organizations --query "OrganizationSummaries[?State == 'Active'].[OrganizationId]" --output text > tmpFile)
ORGANIZATION_ID=$(<tmpFile)
rm -f tmpFile
echo "Workmail-OrganizationID: $ORGANIZATION_ID"

# list users 
$(aws --region $AWS_REGION workmail list-users --organization-id "$ORGANIZATION_ID" --query "Users[?State == 'ENABLED'] | [0].[Id]" --output text > tmpFile)
USER_ID=$(<tmpFile)
rm -f tmpFile

while [[ "$USER_ID" == "S-"*  ]]
do
  echo "deregister user: $USER_ID"
  $(aws --region "$AWS_REGION" workmail deregister-from-work-mail --organization-id "$ORGANIZATION_ID" --entity-id "$USER_ID")
  sleep 5
  echo "delete user: $USER_ID"
  $(aws --region "$AWS_REGION" workmail delete-user --organization-id "$ORGANIZATION_ID" --user-id "$USER_ID" )
  echo "wait and select another user..."
  sleep 5
  $(aws --region $AWS_REGION workmail list-users --organization-id "$ORGANIZATION_ID" --query "Users[?State == 'ENABLED'] | [0].[Id]" --output text > tmpFile)
  USER_ID=$(<tmpFile)
  rm -f tmpFile
done

echo "delete userdirectory..."
echo "...  get resource id"
$(aws --region "$AWS_REGION" cloudformation describe-stack-resource --stack-name webhosting-4--workemail --logical-resource-id simpleDirectory --query "StackResourceDetail.PhysicalResourceId" --output text > tmpFile)
PHYSRESID=$(<tmpFile) 
rm -f tmpFile
echo "...  delete resource $PHYSRESID"
$(aws --region "$AWS_REGION" ds delete-directory --directory-id "$PHYSRESID")
sleep 200
echo "...  delete stack"
$(aws --region "$AWS_REGION" cloudformation delete-stack --stack-name webhosting-4--workemail)
sleep 200
echo "delete HTML files..."
$(aws s3 rb s3://www.$DOMAIN_NAME --force)
sleep 50

echo "delete cloudfront and bucket..."
$(aws --region "$AWS_REGION" cloudformation delete-stack --stack-name webhosting-3--cloudfront)

sleep 10 
echo "delete DNS records..."
$(aws --region "$AWS_REGION" cloudformation delete-stack --stack-name webhosting-2--DNS-records)

sleep 10 
echo "delete certificate..."
$(aws --region "$AWS_REGION_US" cloudformation delete-stack --stack-name webhosting-1--certificate)

echo "all sources were deleted"
exit