#!/bin/bash
export AWS_REGION=eu-west-1

echo 'Enter your AWS ACCESS KEY ID(i.e. AKKSSKSKSKKDKDKDLDFK):'
read awskey
export AWS_ACCESS_KEY_ID=$awskey

echo 'Enter your AWS SECRET ACCESS KEY(i.e. xysvbasudqwbdbdasWWdSdSS/233sdwidwidi323nd9):'
read awssecret
export AWS_SECRET_ACCESS_KEY=$awssecret

echo 'Enter the username of your new user (i.e. contact):'
read euser
export USERNAME=$euser

echo 'Enter the display name of your new email account (i.e. 'Example-Support'): '
read disname
export DISPLAYNAME=$disname



echo "select domain name..."
$(aws --region $AWS_REGION cloudformation list-exports --query "Exports[?Name=='DomainName'].[Value]" --output text > tmpFile)
DOMAIN_NAME=$(<tmpFile)
rm -f tmpFile
echo "domainname is $DOMAIN_NAME"


echo "select OrganizationID..."
$(aws --region $AWS_REGION workmail list-organizations --query "OrganizationSummaries[?State == 'Active'].[OrganizationId]" --output text > tmpFile)
ORGANIZATION_ID=$(<tmpFile)
rm -f tmpFile
echo "Workmail-OrganizationID: $ORGANIZATION_ID"

echo "create new user $USERNAME"
$(aws --region $AWS_REGION workmail create-user --organization-id "$ORGANIZATION_ID" --name "$USERNAME" --display-name "$DISPLAYNAME" --password "AWS@mail:500" --query "UserId" --output text > tmpFile)
USERID=$(<tmpFile)
rm -f tmpFile
echo "UserId is $USERID"


USEREMAIL="$USERNAME@$DOMAIN_NAME"
echo "create email inbox $USEREMAIL"
$(aws --region $AWS_REGION workmail register-to-work-mail --organization-id "$ORGANIZATION_ID" --entity-id "$USERID" --email "$USEREMAIL")

echo "email $USEREMAIL was created" 

echo "End..."
exit

