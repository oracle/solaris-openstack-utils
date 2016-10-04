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
stack_name=$1

if [ $# -eq 2 ]; then
	flavor=$2
else
	# Kernel Zone
	flavor=2
fi

# source our environment for the project

if [ -z "$stack_name" ]; then
	echo "Need arg of stack name"
	exit 1
fi
source ../env/admin_proj_0001.env

keypairname="k1"
keypairpath=~/$keypairname-keypair.pem

# check if key exists
keyr=$(openstack keypair list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}' | grep $keypairname)
# This could be more secure in key placement
if [ -z "$keyr" ]; then
	openstack keypair create $keypairname > $keypairpath 2>&1
	if [ $? -ne  0 ]; then
		exit 1
	fi
fi
chmod 0600 $keypairpath

# Get first image of this platform's architecture that has "cbinit" string
myarch=$(uname -p)
if [ "$myarch" = "i386" ]; then
	seekarch="x86_64"
elif [ "$myarch" = "sparc" ]; then
	seekarch="sparc64"
fi
# this could be improved
imagel=$(openstack image list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
archl=""
testimg=""
for img in $imagel
do
	iarch=$(openstack image show $img | grep properties | sed '/^+/ d' | sed 's/|//g' | sed "s/.*u'architecture': u'//g" | sed "s/'}//g")
	iname=$(openstack image show $img| sed '/^+/ d' | sed 's/|//g' | grep name | awk '{print $2}')
	if [ $seekarch = $iarch ]; then
		if [[ "$iname" =~ "cbinit" ]]; then
			testimg=$img
			break
		fi
        fi		
done


if [ "$testimg" = "" ]; then
	echo "No valid cbinit image found."
	exit 1
fi

time_start_ostackapi=$(date "+%s.%N")

heat stack-create -f ./heat-test.yaml -P "flavor=$flavor;key_name=$keypairname;image=$testimg;public_net=external;private_net=proj_0001_internal" $stack_name

# wait up to 15 minutes
cnt=450
i=0
while [ $i -lt $cnt ]; do
	stackstatus=$(heat stack-list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | grep "\<$stack_name\>" | awk '{print $3}' | tr '\n' )
	echo \"$stackstatus\"
	if [ "$stackstatus" = "CREATE_COMPLETE" ]; then
		break
        fi		
	sleep 2
	((i+=1))
done

# Get the IP and log in
intip=$(openstack server list | tail +3 | sed '/^+/ d' | sed 's/|//g' | sed 's/^[ \t]*//' | grep "\<$stack_name\>" | awk '{print $4}' | sed 's/.*=//g' | sed 's/,.*//g' | tr -d \\n )

echo "Waiting for VM IP response..."
ping $intip 500
time_end_ostackapi=$(date "+%s.%N")
time_start_sshdwait=$(date "+%s.%N")
echo "Waiting more for sshd to come up..."

rc=1
while [[ $rc -ne 0 ]]; do
	netcat -zv $intip 22 > /dev/null 2>&1
	rc=$?
	sleep 1
done

time_end_sshdwait=$(date "+%s.%N")
time_elap_ostackapi=$(echo "$time_end_ostackapi - $time_start_ostackapi" | bc)
time_elap_sshdwait=$(echo "$time_end_sshdwait - $time_start_sshdwait" | bc)
time_elap_vm=$(echo "$time_end_sshdwait - $time_start_ostackapi" | bc)
echo "Elapsed waiting for IP: $time_elap_ostackapi secs"
echo "Elapsed waiting for sshd: $time_elap_sshdwait secs"
echo "Elapsed waiting for Heat Stack VM overall: $time_elap_vm secs"

# check if user_data script ran successfully
# This is created by the heat-test.yaml script
userdpath=/var/tmp/user_data_invoked
userdstat=$(ssh -i $keypairpath root@$intip "test -e $userdpath && echo $?")
if [ "$userdstat" -ne "0" ]; then
	echo "user_data was not invoked.  Is cloudbase-init pacakage installed in VM image?"
	exit 1
fi

ssh -i $keypairpath root@$intip
