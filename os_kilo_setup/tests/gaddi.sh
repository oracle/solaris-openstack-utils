#!/bin/ksh

source ../env/admin_proj_0001.env

name=$1
iname=$2

archs=$(archiveadm info -p $name | grep ^archive)
rel=$(uname -r)

if [ "$rel" = "5.11" ]; then
	arch=$(echo $archs | cut -d '|' -f 4)
else
	arch=$(echo $archs | cut -d '|' -f 5)
fi
if [ "$arch" = "i386" ]; then
	imgarch="x86_64"
else
	imgarch="sparc64"
fi

#cat $name | glance  image-create --container-format bare --disk-format raw --is-public true --name $iname --property architecture=$imgarch --property hypervisor_type=solariszones --property vm_mode=solariszones
openstack image create --container-format bare --disk-format raw --file $name --public --property architecture=$imgarch --property hypervisor_type=solariszones --property vm_mode=solariszones $iname

if [ $? != 0 ]; then
	echo "ERROR: adding image"
	exit 1
fi

exit 0
