#!/bin/ksh
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
name=$1

if [ $# -gt 1 ]; then
	flavor="$2"
else
	# Kernel Zone
	flavor="2"
fi

if [ $# -gt 2 ]; then
	cwait=$3
fi

if [ $# -gt 3 ]; then
	pubip=$4
else
        pubip=true
fi

if [ -z "$name" ]; then
	echo "$0 <vmname>"
	exit 1
fi

keypairname="k1"
keypairpath=~/$keypairname-keypair.pem

# source our environment for the project
source ../env/admin_proj_0001.env
# check if key exists
keyr=$(openstack keypair list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}' | grep $keypairname)
# This could be more secure in key placement
if [ -z "$keyr" ]; then
	openstack keypair create $keypairname > $keypairpath 2>&1
	if [ $? != 0 ]; then
		exit 1
	fi
fi
chmod 0600 $keypairpath

# Get first listed image for this architecutre
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
	if [ $seekarch = $iarch ]; then
		testimg=$img
		break
        fi		
done

if [ -z "$testimg" ]; then
	echo "ERROR: could not find valid image"
	exit 1
fi

time_start_ostackapi=$(date "+%s.%N")

if [ -z "$cwait" ]; then
	openstack server create --image $testimg --flavor $flavor --key-name $keypairname $name
else
	openstack server create --wait --image $testimg --flavor $flavor --key-name $keypairname $name
fi
if [ $? != 0 ]; then
	echo "ERROR: creating server"
	exit 1
fi

if [ "$pubip" = true ]; then
    # Use next available IP and assign it
    # External IP is only accessible outside this node
    next_ip=$(openstack ip floating list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $3}' | tail -1)
    openstack ip floating add "${next_ip}" $name
    if [ $? != 0 ]; then
        echo "ERROR: assigning floating ip"
    fi
    echo "Assigning floating IP to VM: ${next_ip}"
fi

if [ -z "$cwait" ]; then
	# You will need to manually log in when the server is in ACTIVE state
	exit 0
fi	
intip=$(openstack server list | tail +3 | grep "\<${name}\>" | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $4}' | sed 's/.*=//g' | sed 's/,.*//g' | tr -d \\n )

echo Waiting for VM IP to respond...
ping $intip 500
time_end_ostackapi=$(date "+%s.%N")
time_start_sshdwait=$(date "+%s.%N")
echo VM responded, waiting for sshd...

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
echo "Elapsed waiting for VM overall: $time_elap_vm secs"

ssh -i $keypairpath root@$intip
