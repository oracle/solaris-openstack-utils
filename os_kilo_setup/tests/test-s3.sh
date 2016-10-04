#!/bin/ksh

# Copyright 2016 Oracle Corporation
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

# FQDN may be required
S3HOST=`hostname`

if [[ ! -f "s3-curl/s3curl.pl.bak" ]]; then
	cp s3-curl/s3curl.pl s3-curl/s3curl.pl.bak
fi
cat s3-curl/s3curl.pl.bak | sed '/my @endpoints/,/);/d' | gsed "/# begin customizing here/a my @endpoints = ('$S3HOST');" > s3-curl/s3curl.pl
chmod 755 s3-curl/s3curl.pl

EC2_ACCESS_KEY=$(cat /etc/keystone/ec2rc | grep ADMIN_ACCESS | sed 's/[^=]*=//')
EC2_SECRET_KEY=$(cat /etc/keystone/ec2rc | grep ADMIN_SECRET | sed 's/[^=]*=//')

unset http_proxy
unset https_proxy
# list all buckets
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --get -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/
# create bucket
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --put /dev/null -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone
# add object to bucket
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --put /etc/motd -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone/motd
# get listing of buecket
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --get -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone
# get the object back
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --get -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone/motd > /dev/null
# delete the object
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --del -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone/motd
# check to see if object is deleted
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --get -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone
# delete the newly created bucket
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --del -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080/bucketone
# check to see that bucket is deleted
s3-curl/s3curl.pl --id $EC2_ACCESS_KEY --key $EC2_SECRET_KEY --get -- --cacert /etc/swift/ssl/public/ca-chain.pem https://$S3HOST:8080
