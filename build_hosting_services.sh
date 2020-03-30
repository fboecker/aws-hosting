#!/bin/bash
export AWS_REGION=eu-west-1
export AWS_REGION_US=us-east-1

echo 'Enter your AWS ACCESS KEY ID(i.e. AKKSSKSKSKKDEXAMPLE):'
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

if [ $(tr "[:upper:]" "[:lower:]" <<< "$success") != "y" ];then echo 'AWS stack will not be executed!' && exit ;fi


echo "create certificate..."
aws --region $AWS_REGION_US cloudformation create-stack --stack-name webhosting-1--certificate --template-body file://cloudformation-scripts/1_create_certificate.yml --parameters ParameterKey=DomainName,ParameterValue=$DOMAIN_NAME

echo "waiting..."
sleep 20

echo "get certificate ID..."
$(aws --region $AWS_REGION_US cloudformation describe-stack-resource --stack-name webhosting-1--certificate --logical-resource-id WebsiteCertificate --query "StackResourceDetail.PhysicalResourceId" > tmpFile)
certificateId=$(<tmpFile)
certificateId=${certificateId//\"}
rm -f tmpFile
#echo "CertificateID: $certificateId"

echo "get DNS recordName..."
$(aws --region "$AWS_REGION_US" acm describe-certificate --certificate-arn "$certificateId" --query "Certificate.DomainValidationOptions[0].ResourceRecord.Name" > tmpFile)
RecordName=$(<tmpFile)
RecordName=${RecordName//\"}
rm -f tmpFile
#echo "RecordName: $RecordName"

echo "get DNS recordValue..."
$(aws --region "$AWS_REGION_US" acm describe-certificate --certificate-arn "$certificateId" --query "Certificate.DomainValidationOptions[0].ResourceRecord.Value" > tmpFile)
RecordValue=$(<tmpFile)
RecordValue=${RecordValue//\"}
rm -f tmpFile
#echo "RecordValue: $RecordValue"

echo "add DNS record..."
$(aws --region "$AWS_REGION" cloudformation deploy --stack-name webhosting-2--DNS-records --template-file cloudformation-scripts/2_add_certificate_dns_records_to_route53.yml --parameter-overrides DomainName=$DOMAIN_NAME RecordName=$RecordName RecordValue=$RecordValue) 

echo "get certificate status..."
brk="false"
while [ "$brk" == "false" ]
do
  echo "waiting for 60 seconds..."
  sleep 60
#  echo "get certificate status..."
  $(aws --region "$AWS_REGION_US" acm describe-certificate --certificate-arn "$certificateId" --query "Certificate.Status" > tmpFile)
  certStatus=$(<tmpFile) 
  certStatus=${certStatus//\"}
  rm -f tmpFile 
  if [ "$certStatus" == "ISSUED" ]; then brk="true"; fi
done

echo "create cloudfront distribution..."
aws --region "$AWS_REGION" cloudformation deploy --stack-name webhosting-3--cloudfront --template-file cloudformation-scripts/3_create_cloudfront_distribution.yml --parameter-overrides DomainName=$DOMAIN_NAME CertificateARN=$certificateId 
echo "your AWS hosting services are running now"

