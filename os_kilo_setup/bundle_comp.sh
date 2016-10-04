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
osdir=$PWD
ddat=$osdir/dat

#keyspub=keys/intermediate/certs
#tlsd=$PWD/keys
#mkdir -p $keyspub
#cp $ddat/$keyspub/ca-chain.cert.pem $osdir/$keyspub

cat $ddat/var/user/evsuser/id_rsa.pub >> /var/user/evsuser/.ssh/authorized_keys

mkdir -p /etc/swift
cp $ddat/etc/swift/swift.conf /etc/swift/swift.conf
cp $ddat/etc/swift/*.ring.gz /etc/swift

cd $osdir
