#!/bin/bash

# place this file inside /home/ubuntu/mongo_backup
# add crontab (crontab -e; @daily /home/ubuntu/mongo_backup/mdump.sh)
# Make sure to set chmod +x to mdump.sh

# Requirements
# 1. mongodump (apt get mongodb-org-tools)
# 2. pigz (apt get pigz)

## notes
# - we are not taking backup of config or admin db

location='/home/ubuntu/mongo_backup' # this should exist

awsUser='' # IAM access key
awsPass='' # IAM secret key
awsRegion='us-east-1'

dbUser='' #mongo user
dbPass='' #mongo pass
dbList=('ds-user' 'ds-core' 'ds-notifier')

s3Bucket='s3://<BUCKET_NAME_HERE>/<PATH_HERE>/' # set s3 bucket here

now=$(TZ=UTC date '+%Y%m%d-%H%M%S') # get current date and time in UTC

# change directory; try to create and change if fails; exit if all fails
cd $location || mkdir -p $location && cd "$_" || exit

echo 'Dumping DB(s)'
for db in "${dbList[@]}"
do
  mongodump --username="$dbUser" --password="$dbPass" --authenticationDatabase=admin --out=$location/dump --db="$db"
done

echo 'Zipping up!'
tar -c --use-compress-program=pigz -f prod_"$now".mongo.gz dump

echo 'Deleting raw dump!'
rm -rf $location/dump

echo 'Transferring to S3'
# AWS CLI requires AWS credentials to be set up
export AWS_ACCESS_KEY_ID=$awsUser
export AWS_SECRET_ACCESS_KEY=$awsPass
export AWS_DEFAULT_REGION=$awsRegion
aws s3 cp $location/prod_$now.mongo.gz $s3Bucket # transfer to s3
echo 'Deleting 8 days older backups from disk!'
find $location -name '*.mongo.gz' -type f -mtime +8 -exec rm -f {} \;
echo 'All done!'