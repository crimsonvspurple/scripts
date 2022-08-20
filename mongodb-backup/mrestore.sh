#!/bin/bash

# Use this to rapidly restore a DB from s3 for local task

# place this file somewhere
# Make sure to set chmod +x to mrestore.sh

# Requirements
# 1. mongorestore (apt get mongodb-org-tools)
# 2. pigz (apt get pigz)

## notes
# - we are not taking backup of config or admin db

location='/home/ubuntu/work/ds/dump/ds-db' # this should exist

awsUser='' # IAM access key
awsPass='' # IAM secret key
awsRegion='us-east-1'

s3Bucket="s3://<BUCKET_NAME_HERE>/<PATH_HERE>/" # set s3 bucket here (with path)

# change directory; try to create and change if fails; exit if all fails
cd $location || mkdir -p $location && cd "$_" || exit


echo 'Transferring from S3'
# AWS CLI requires AWS credentials to be set up
export AWS_ACCESS_KEY_ID=$awsUser
export AWS_SECRET_ACCESS_KEY=$awsPass
export AWS_DEFAULT_REGION=$awsRegion

# get latest DB backup name
backupName="$(aws s3 ls $s3Bucket | sort | tail -n 1 | awk '{print $4}')"

# now copy that file to local directory
aws s3 cp "$s3Bucket""$backupName" .

echo 'Unzip using pigz in ./dump'
tar -I pigz -xf "$backupName" -C .

echo 'Restoring DB(s) from ./dump'
mongorestore --drop --preserveUUID # this assumes local DB has no auth check

echo 'Deleting raw dump! Downloaded zip from S3 is not deleted.'
rm -rf ./dump

echo 'All done!'
