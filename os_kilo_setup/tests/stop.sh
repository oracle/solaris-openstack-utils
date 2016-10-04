#!/bin/sh
#
# Clean up for reboot
#

# HEAT STACKS
source ../env/admin_proj_0001.env
stacks=$(heat stack-list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
for s in $stacks
do
	echo $s
	heat stack-delete $s
done
while [ ! -z $servers ]
do
	stacks=$(heat stack-list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
	sleep 1
done
source ../env/admin_proj_0002.env
stacks=$(heat stack-list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
for s in $stacks
do
	echo $s
	heat stack-delete $s
done
while [ ! -z $servers ]
do
	stacks=$(heat stack-list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
	sleep 1
done

# VMs
source ../env/admin_proj_0001.env
servers=$(openstack server list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
for s in $servers
do
	echo $s
	openstack server delete $s
done
while [ ! -z $servers ]
do
	servers=$(openstack server list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
	sleep 1
done
source ../env/admin_proj_0002.env
servers=$(openstack server list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
for s in $servers
do
	openstack server delete $s
done
while [ ! -z $servers ]
do
	servers=$(openstack server list | tail +3 | sed '/^+/ d' | sed 's/|//g'| sed 's/^[ \t]*//' | awk '{print $1}')
	sleep 1
done

# Related services
ostack_svcs=$(svcs | grep openstack | awk '{print $3}')
other_svcs="mysql evs-controller evs ipfilter"
echo "Disabling following services: $ostack_svcs $other_svcs"
rsvcs="$ostack_svcs $other_svcs"
if [ ! -z "$rsvcs" ]
then
	echo "services disable: $rsvcs"
	svcadm disable -ts $rsvcs
fi

# Anything else
zone_instl=$(zoneadm list | grep "instance-")
for z in $zone_instl
do
	zoneadm -z $z shutdown
	zoneadm -z $z uninstall
done

# Cleanup local stores
rpooll="cinder glance swift"
for rp in $rpooll
do
	zfs destroy -r rpool/$rp > /dev/null 2>&1
done

for rp in $rpooll
do
	zfs destroy -r tank/$rp > /dev/null 2>&1
done

exit 0
