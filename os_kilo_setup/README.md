# Openstack Kilo on Solaris 11.3 SRU9+ Bring-Up Test Tool

## Introduction

Instructions for single node and multi-node deployments follow.  The script
variables should be inspected before invocation because they contain
information about the environment.   The script will create a demo
network and upload UAR images from the ./images diretory for use in testing.
It is created for testing purposes of the Openstack environment on
Solaris.  It is suggested that configuration management tools like Chef or
Puppet be used to configure a production environment.  It is also suggested
to validate the security of the setup before placing into production.

NOTE: The self-signed certificates created by this tool are not
      intended for production use.

It is highly recommended you create and mount a new boot envirnoment before
proceeding.  This will providate a snapshot to revert to if configuration
needs to be applied fresh.

By default this script will bring up Openstack with TLS/SSL using
self-signed certs.  If you're using the WebGUI, then you may need
to clear your browser's CA for "Oracle Test" authority between iterations
of invoking this script.

## Instructions

1. Download Unified Archive images to use for compute instances.  The
   images you use depend on which architecture the compute node is.

SPARC (Patch 24745105) 11.3 UAR image:
[Oracle MOS Link](https://support.oracle.com/epmos/faces/PatchResultsNDetails?_adf.ctrl-state=119zeykz9v_9&releaseId=400000110000&requestId=20630501&patchId=24745105&languageId=0&platformId=23&searchdata=%3Ccontext+type%3D%22BASIC%22+search%3D%22%26lt%3BSearch%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bpatch_number%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3B24745105%26quot%3B%2F%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bexclude_superseded%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3Bfalse%26quot%3B%2F%26gt%3B%0A%26lt%3B%2FSearch%26gt%3B%22%2F%3E&_afrLoop=473399882831516)

X86 (Patch 24745114) 11.3 UAR image:
[Oracle MOS Link](https://support.oracle.com/epmos/faces/PatchResultsNDetails?_adf.ctrl-state=119zeykz9v_9&releaseId=400000110000&requestId=20630513&patchId=24745114&languageId=0&platformId=267&searchdata=%3Ccontext+type%3D%22BASIC%22+search%3D%22%26lt%3BSearch%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bpatch_number%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3B24745114%26quot%3B%2F%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bexclude_superseded%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3Bfalse%26quot%3B%2F%26gt%3B%0A%26lt%3B%2FSearch%26gt%3B%22%2F%3E&_afrLoop=473361805377861)

These images should have Cloudbase services in them and should work with
Heat stack orchestration.  To utilize this, add "-cbinit.uar" to end of
the image name.  The scripts included here will look for "cbinit" string
when choosing an appropiate image for heat.

Place the images in the ./os_kilo_setup/images directory, the script will automatically
add them to Glance image store during bring-up.

2. Install packages

```
$ pkg install openstack
```

3. Create a new boot environment to fall back to and boot into it

```
$ beadm create -a ostk-k && reboot
```

4. Create a boot environment to install Openstack using this script.  We can
   fall back to the 'ostk-k' environment if there is a mistake.  Boot into
   the environment to start the Openstack configuration.

```
$ beadm create -a osk0 && reboot
```

5. Now that your in the install boot environment, edit configuration parameters,
   specifically with regards to your networking section.

```
$ vi os_kilo_setup.py
```

## Single Node

6. Bring-up single node of Openstack

```
$ ./os_kilo_setup.py singlenode
```

7. If the script fails, create a new clean boot environment, boot into it, modify
   the configuration parameters and re-run the script.  Note only perform this step
   if the script failed.

```
$ cat os_kilo_setup/tests && ./stop.sh && beadm create -a -e ostk-k osm1 && reboot
```

   If the script fails a second time, use above command and substitute 'osm2' for
   'osm1'.  Keep incrementing this number and delete the old boot environments later
   when time permits.


8. When complete you can start using Openstack via the CLI or WebGUI.  There
are test scripts located in ./tests.

# Create a VM using Kernel Zones with floating IP

```
$ cd ./tests
$ ./vmcreatew.sh s1
```

# Create a VM using Non-Global Zones with floating IP

```
$ cd ./tests
$ ./vmcreatew-ngz.sh s1
```

# Create a VM using Kernel Zones *without* floating IP

```
$ cd ./tests
$ ./vmcreatew-noip.sh s1
```

# A ssh login shell to the VM is established after VM is created.

```
$ cd ./tests
```

# For Kernel Zones

```
$ ./hstacktest.sh hs1
```

# For Non-Global Zones

```
$ ./hstacktest-ngz.sh hs1
```

# The test will validate user_data script is invoked and log in via ssh

Log into Horizon WebGUI dashboard.

For the values in this default script go to following URLs depending on if
USE_SSL is specified in the script.

Username: proj_admin_0001
Password: adminpw

Username: $TENANT_NET_LIST_username
Password: $ADMIN_PASSWORD

9. To use commands env files can be sourced. For example:

```
$ source ./env/admin_proj_0000.env

$ openstack --help 2>&1 | less
```

## Multi-node

1. Configure multi-node

The following instructions allow configuration of a controller node and compute
node.  The controller node will run most of the Openstack services and the compute
node will run the hypervisor where VMs will launch and Swift storage node as well.

Use the same method of keeping a clean boot environment described in the single node
instructions above.  This will allow one to roll back in case of configuration error.
On the controller node:

```
$ pkg install openstack
```

Modify os_kilo_python.py and change following parameters:
SINGLE_NODE = False
CONTROLLER_NODE = ctl.example-net1.com
COMPUTE_NODE = comp0.example-net1.com

Make sure NTP is correctly configured.

```
$ pkg install ntp
```

Update NTP parameters for your environment's NTP server.
```
$ vi /etc/inet/ntp.conf
```

Restart NTP

```
$ svcadm restart ntp
```

```
$ ./os_kilo_setup.py controller
```

2. Prepare a bundle for next node

```
$ ./bundle_ctl.sh
```

# Copy to compute node

```
$ scp bundle.tgz user@comp0.example.com:~
```

# Log into compute node and unpack bundle

Make sure NTP is correctly configured.

```
$ pkg install ntp
```

Update NTP parameters for your environment's NTP server.
```
$ vi /etc/inet/ntp.conf
```

Restart NTP

```
$ svcadm restart ntp
```

```
$ pkg install openstack

$ ssh user@comp0.example.com

$ tar xzvf ~/bundle.tgz

$ su

$ cd os_kilo_setup

$ ./bundle_comp.sh

$ ./os_kilo_setup.py compute

$ ./bundle_compctl.sh
```

# Follow the steps and copy necessary files.

3. Two nodes should be configured.  See step 2 for tests.

4. To use commands env files can be sourced. For example:

```
$ source ./env/admin_proj_0001.env

$ openstack --help 2>&1 | less
```
