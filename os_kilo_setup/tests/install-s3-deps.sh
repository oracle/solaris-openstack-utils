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

# export https_proxy=
# export http_proxy=

if [[ ! -f "s3-curl.zip" ]]; then
	curl -O http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
fi
rm -rf s3-curl
unzip s3-curl.zip
cp s3-curl/s3curl.pl s3-curl/s3curl.pl.bak
cat s3-curl/s3curl.pl.bak | grep -v "sleep 5;" > s3-curl/s3curl.pl
rm s3-curl/s3curl.pl.bak
chmod 755 s3-curl/s3curl.pl

if [[ ! -f "Digest-HMAC-1.03.tar.gz" ]]; then
	wget http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/Digest-HMAC-1.03.tar.gz
fi
tar xzvf Digest-HMAC-1.03.tar.gz
curdir=$PWD
cd Digest-HMAC-1.03
perl Makefile.PL
make
make install
cd $curdir
rm -rf Digest-HMAC-1.03*
rm s3-curl.zip
