#!/bin/bash

# Customise the application deployment by modifying the variabels below.
# set -x

export APPNAME="changeme" #must be lowercase alphaonly.
export S3BUCKET="changeme-$APPNAME"
export EC2KeyPairName="CHANGEME"
export DBPASSWORD="changeme" #18 digets alphanumerical
export STACKTYPE="spring"


# Check for the basics, jq, aws, svn, access keys...
YUM_CMD=$(command -v yum)
APT_GET_CMD=$(command -v apt)
if [[ -n $YUM_CMD ]]; then
  sudo yum install -y jq subversion awscli
elif [[ -n $APT_GET_CMD ]]; then
  sudo apt-get install -y jq subversion awscli
else
echo "Could not install package."
exit 1
fi

if command -v jq >/dev/null 2>&1 ; then
    echo "found: $(jq --version)"
else
    if [[ -n $YUM_CMD ]]; then
        sudo yum install -y jq
    elif [[ -n $APT_GET_CMD ]]; then
        sudo apt-get install -y jq
    else
        echo "Could not install jq."
        exit 1
    fi
fi

if command -v aws >/dev/null 2>&1 ; then
    echo "found: $(aws --version)"
else
    if [[ -n $YUM_CMD ]]; then
        sudo yum install -y aws
    elif [[ -n $APT_GET_CMD ]]; then
        sudo apt-get install -y aws
    else
        echo "Could not install aws cli."
        exit 1
    fi
fi

if command -v svn >/dev/null 2>&1 ; then
    echo "found: $(aws --version)"
else
    if [[ -n $YUM_CMD ]]; then
        sudo yum install -y subversion
    elif [[ -n $APT_GET_CMD ]]; then
        sudo apt-get install -y subversion
    else
        echo "Could not install aws subversion."
        exit 1
    fi
fi

if ! grep aws_access_key_id ~/.aws/credentials -q "aws_secret_access_key" ~/.aws/credentials
  then echo "aws appears to be misconfigured, please run  aws configure"
  exit 0
fi

if ! grep aws_secret_access_key ~/.aws/credentials -q "aws_secret_access_key" ~/.aws/credentials
  then echo "aws appears to be misconfigured, please run  aws configure"
  exit 0
fi

# Dynamic Vars, Don't change.
__FILENAME="$APPNAME.zip"
__SEEDURL="https://s3.amazonaws.com/$S3BUCKET/$__FILENAME"
__PIPELINEBUCKET="$(aws s3 ls | grep "$APPNAME-pipe" | cut -d ' ' -f3)"
export __FILENAME __SEEDURL __PIPELINEBUCKET

# The application specific pipeline bucket must not exist when deploying the app. Delete stack will not clean up S3. This will warn if a manuel delete is needed.

if [ "${#__PIPELINEBUCKET}" -gt 0 ]
then
  echo "$__PIPELINEBUCKET"
  echo "Error: Found a previous S3 bucket for Application: s3://$__PIPELINEBUCKET. Delete via console, or choose a new APPNAME."
else
  echo "Deploying Application: $APPNAME"

  # Start CLean.
  [[ -f $__FILENAME ]] && rm $__FILENAME
  [[ -d src ]] && rm -rf src

  # Ensure buckets in place.
  aws s3api create-bucket --bucket $S3BUCKET --acl public-read
  
  # Update the buildspecs BASESTACK with the APPNAME.
  sed -i "s/DYNAMIC/$APPNAME/g" buildspec.yml

  # Move cloudformation templates, and reposource archive to S3.
  aws s3 sync templates/ s3://$S3BUCKET --acl public-read

  # Archive everything and upload to S3. This archive will be the base for the seedrepo.
  zip -r $__FILENAME . > /dev/null
  aws s3 cp $__FILENAME s3://$S3BUCKET --acl public-read

  # Clean up again.
  [[ -f $__FILENAME ]] && rm $__FILENAME
  [[ -d src ]] && rm -rf src

  # Deploy the Application.
  echo "Please wait while the application deploys, Status can be seen from cloudformation console."
  aws cloudformation deploy --template-file templates/deploy.yml --stack-name $APPNAME --capabilities CAPABILITY_NAMED_IAM --parameter-overrides \
  StackType=$STACKTYPE \
  EC2KeyPairName=$EC2KeyPairName \
  DatabasePassword=$DBPASSWORD \
  seedURL=$__SEEDURL \
  TemplateBucket=$S3BUCKET
fi

SSHCloneURL=$(aws cloudformation describe-stacks --stack-name $APPNAME | jq .Stacks[].Outputs | jq -r '.[] | select(.OutputKey=="SSHCloneURL") | .OutputValue')
EnvironmentURL=$(aws cloudformation describe-stacks --stack-name $APPNAME | jq .Stacks[].Outputs | jq -r '.[] | select(.OutputKey=="EnvironmentURL") | .OutputValue')

echo "###################################"
echo "Your application will be ready soon"
echo "###################################"
echo ""
echo "EnvironmentURL: $EnvironmentURL"

echo "##########################"
echo "Customise your application"
echo "##########################"
echo ""
echo "SSHCloneURL: $SSHCloneURL"

