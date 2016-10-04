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
prepd=`mktemp -d /var/tmp/os_kilo_setup_XXX`
osb=$prepd/os_kilo_setup
osd=$osb/dat

keyspub=keys/intermediate/certs
keyspriv=keys/intermediate/private
tlsd=$PWD/keys
mkdir -p $osb/$keyspub
mkdir -p $osb/$keyspriv

# XXX improve to only copy necessary keys.
cp $PWD/$keyspub/ca-chain.cert.pem $osb/$keyspub
cp $PWD/$keyspub/*-server*.cert.pem $osb/$keyspub
cp $PWD/$keyspriv/*-server.key.pem $osb/$keyspriv

mkdir -p $osd/var/user/evsuser
sshevsuser_keyp=/var/user/evsuser/.ssh
cp $sshevsuser_keyp/id_rsa.pub $osd/var/user/evsuser
# cp /root/.ssh/id_rsa.pub ctl:/var/user/evsuser/.ssh/authorized_keys

mkdir -p $osd/etc/swift
cp /etc/swift/swift.conf $osd/etc/swift
cp /etc/swift/*.ring.gz $osd/etc/swift

cp -r os_kilo_setup.py os_keygen.py bundle*.sh keystone_data.sh mysql.cnf *.cnf patches rabbitmq.config.ssl tests $osb

tdir=$PWD
cd $prepd
tar czvf $tdir/bundle.tgz *
cd $tdir
rm -rf $prepd
