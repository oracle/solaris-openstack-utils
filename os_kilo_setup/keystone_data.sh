#!/usr/bin/env bash

# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Copyright 2016 Oracle Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

# Sample initial data for Keystone using python-openstackclient
#
# This script is based on the original DevStack keystone_data.sh script.
#
# It demonstrates how to bootstrap Keystone with an administrative user
# using the OS_TOKEN and OS_URL environment variables and the administrative
# API.  It will get the admin_token (OS_TOKEN) and admin_port from
# keystone.conf if available.
#
# Disable creation of endpoints by setting DISABLE_ENDPOINTS environment
# variable. Use this with the Catalog Templated backend.
#
# A EC2-compatible credential is created for the admin user and
# placed in etc/ec2rc.
#
# Tenant               User      Roles
# -------------------------------------------------------
# demo                 admin     admin
# service              glance    admin
# service              nova      admin
# service              ec2       admin
# service              swift     admin
# service              neutron   admin
# service              cinder    admin
# service              heat      admin
# service              ironic    admin

# By default, passwords used are those in the OpenStack Install and Deploy
# Manual. One can override these (publicly known, and hence, insecure)
# passwords by setting the appropriate environment variables. A common default
# password for all the services can be used by setting the "SERVICE_PASSWORD"
# environment variable.

PATH=/usr/bin

ADMIN_PASSWORD=${ADMIN_PASSWORD:-secrete}
NOVA_PASSWORD=${NOVA_PASSWORD:-${SERVICE_PASSWORD:-nova}}
GLANCE_PASSWORD=${GLANCE_PASSWORD:-${SERVICE_PASSWORD:-glance}}
EC2_PASSWORD=${EC2_PASSWORD:-${SERVICE_PASSWORD:-ec2}}
SWIFT_PASSWORD=${SWIFT_PASSWORD:-${SERVICE_PASSWORD:-swift}}
NEUTRON_PASSWORD=${NEUTRON_PASSWORD:-${SERVICE_PASSWORD:-neutron}}
CINDER_PASSWORD=${CINDER_PASSWORD:-${SERVICE_PASSWORD:-cinder}}
HEAT_PASSWORD=${HEAT_PASSWORD:-${SERVICE_PASSWORD:-heat}}
IRONIC_PASSWORD=${IRONIC_PASSWORD:-${SERVICE_PASSWORD:-ironic}}

CONTROLLER_PUBLIC_ADDRESS=${CONTROLLER_PUBLIC_ADDRESS:-localhost}
CONTROLLER_ADMIN_ADDRESS=${CONTROLLER_ADMIN_ADDRESS:-localhost}
CONTROLLER_INTERNAL_ADDRESS=${CONTROLLER_INTERNAL_ADDRESS:-localhost}

NOVA_PUBLIC_ADDRESS=${NOVA_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
NOVA_ADMIN_ADDRESS=${NOVA_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
NOVA_INTERNAL_ADDRESS=${NOVA_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

GLANCE_PUBLIC_ADDRESS=${GLANCE_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
GLANCE_ADMIN_ADDRESS=${GLANCE_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
GLANCE_INTERNAL_ADDRESS=${GLANCE_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

EC2_PUBLIC_ADDRESS=${EC2_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
EC2_ADMIN_ADDRESS=${EC2_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
EC2_INTERNAL_ADDRESS=${EC2_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

SWIFT_PUBLIC_ADDRESS=${SWIFT_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
SWIFT_ADMIN_ADDRESS=${SWIFT_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
SWIFT_INTERNAL_ADDRESS=${SWIFT_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

NEUTRON_PUBLIC_ADDRESS=${NEUTRON_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
NEUTRON_ADMIN_ADDRESS=${NEUTRON_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
NEUTRON_INTERNAL_ADDRESS=${NEUTRON_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

CINDER_PUBLIC_ADDRESS=${CINDER_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
CINDER_ADMIN_ADDRESS=${CINDER_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
CINDER_INTERNAL_ADDRESS=${CINDER_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

HEAT_CFN_PUBLIC_ADDRESS=${HEAT_CFN_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
HEAT_CFN_ADMIN_ADDRESS=${HEAT_CFN_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
HEAT_CFN_INTERNAL_ADDRESS=${HEAT_CFN_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}
HEAT_PUBLIC_ADDRESS=${HEAT_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
HEAT_ADMIN_ADDRESS=${HEAT_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
HEAT_INTERNAL_ADDRESS=${HEAT_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

IRONIC_PUBLIC_ADDRESS=${IRONIC_PUBLIC_ADDRESS:-$CONTROLLER_PUBLIC_ADDRESS}
IRONIC_ADMIN_ADDRESS=${IRONIC_ADMIN_ADDRESS:-$CONTROLLER_ADMIN_ADDRESS}
IRONIC_INTERNAL_ADDRESS=${IRONIC_INTERNAL_ADDRESS:-$CONTROLLER_INTERNAL_ADDRESS}

TOOLS_DIR=$(cd $(dirname "$0") && pwd)
KEYSTONE_CONF=${KEYSTONE_CONF:-/etc/keystone/keystone.conf}
if [[ -r "$KEYSTONE_CONF" ]]; then
    EC2RC="$(dirname "$KEYSTONE_CONF")/ec2rc"
elif [[ -r "$TOOLS_DIR/../etc/keystone.conf" ]]; then
    # assume git checkout
    KEYSTONE_CONF="$TOOLS_DIR/../etc/keystone.conf"
    EC2RC="$TOOLS_DIR/../etc/ec2rc"
else
    KEYSTONE_CONF=""
    EC2RC="ec2rc"
fi

# Extract some info from Keystone's configuration file
if [[ -r "$KEYSTONE_CONF" ]]; then
    CONFIG_SERVICE_TOKEN=$(tr -d '[\t ]' < $KEYSTONE_CONF | \
        grep ^admin_token= | cut -d'=' -f2)
    if [[ -z "${CONFIG_SERVICE_TOKEN}" ]]; then
        # default config options are commented out, so lets try those
        CONFIG_SERVICE_TOKEN=$(tr -d '[\t ]' < $KEYSTONE_CONF | \
            grep ^\#admin_token= | cut -d'=' -f2)
    fi
    CONFIG_ADMIN_PORT=$(tr -d '[\t ]' < $KEYSTONE_CONF | \
        grep ^admin_port= | cut -d'=' -f2)
    if [[ -z "${CONFIG_ADMIN_PORT}" ]]; then
        # default config options are commented out, so lets try those
        CONFIG_ADMIN_PORT=$(tr -d '[\t ]' < $KEYSTONE_CONF | \
            grep ^\#admin_port= | cut -d'=' -f2)
    fi
fi

export OS_TOKEN=${OS_TOKEN:-$CONFIG_SERVICE_TOKEN}
if [[ -z "$OS_TOKEN" ]]; then
    echo "No service token found."
    echo "Set OS_TOKEN manually from keystone.conf admin_token."
    exit 1
fi

if [[ "$TLS_ENDPOINTS" == "true" ]]; then
    PROTOCOL="https"
else
    PROTOCOL="http"
fi

export OS_URL=${OS_URL:-$PROTOCOL://$CONTROLLER_PUBLIC_ADDRESS:${CONFIG_ADMIN_PORT:-35357}/v2.0}

function get_id () {
    echo `"$@" | grep ' id ' | awk '{print $4}'`
}

#
# Default Project
#
openstack project create "${DEFAULT_PROJECT}" \
	--description "Default Project"

openstack user create "${ADMIN_USER}" \
    --project "${DEFAULT_PROJECT}" \
    --password "${ADMIN_PASSWORD}"

openstack role create admin

openstack role add --user "${ADMIN_USER}" \
                   --project "${DEFAULT_PROJECT}" \
                   admin
#
# Service Project
#
openstack project create service \
	--description "Service Project"

#openstack role add --user "${ADMIN_USER}" \
#                   --project "${SERVICE_PROJECT}" \
#                   admin

# Glance User and Role
openstack user create glance --project "${SERVICE_PROJECT}" \
	--password "${GLANCE_PASSWORD}"

openstack role add --user glance \
                   --project "${SERVICE_PROJECT}" \
                   admin

# Nova User and Role
openstack user create nova --project "${SERVICE_PROJECT}" \
	--password "${NOVA_PASSWORD}"

openstack role add --user nova \
                   --project "${SERVICE_PROJECT}" \
                   admin

# EC2 User and Role
openstack user create ec2 --project "${SERVICE_PROJECT}" \
	--password "${EC2_PASSWORD}"

openstack role add --user ec2  \
                   --project "${SERVICE_PROJECT}" \
                   admin

# Swift User and Role
openstack user create swift --project "${SERVICE_PROJECT}" \
	--password "${SWIFT_PASSWORD}"

openstack role add --user swift \
                   --project "${SERVICE_PROJECT}" \
                   admin

# Neutron User and Role
openstack user create neutron --project "${SERVICE_PROJECT}" \
	--password "${NEUTRON_PASSWORD}"

openstack role add --user neutron \
                   --project "${SERVICE_PROJECT}" \
                   admin

# Cinder User and Role
openstack user create cinder --project "${SERVICE_PROJECT}" \
	--password "${CINDER_PASSWORD}"

openstack role add --user cinder \
                   --project "${SERVICE_PROJECT}" \
                   admin

# Heat User and Role
openstack user create heat --project "${SERVICE_PROJECT}" \
	--password "${HEAT_PASSWORD}"

openstack role add --user heat \
                   --project "${SERVICE_PROJECT}" \
                   admin

openstack role create heat_stack_user

# Ironic User and Role
openstack user create ironic --project "${SERVICE_PROJECT}" \
	--password "${IRONIC_PASSWORD}"

openstack role add --user ironic \
                   --project "${SERVICE_PROJECT}" \
                   admin

#
# Keystone service
#
openstack service create --name keystone \
                         --description "Keystone Identity Service" \
                         identity
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$CONTROLLER_PUBLIC_ADDRESS:\$(public_port)s/v2.0" \
	--adminurl "$PROTOCOL://$CONTROLLER_ADMIN_ADDRESS:\$(admin_port)s/v2.0" \
	--internalurl "$PROTOCOL://$CONTROLLER_INTERNAL_ADDRESS:\$(public_port)s/v2.0" \
        keystone
fi

#
# Nova service
#
openstack service create --name=nova \
                         --description="Nova Compute Service" \
                         compute
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$NOVA_PUBLIC_ADDRESS:8774/v2/\$(tenant_id)s" \
	--adminurl "$PROTOCOL://$NOVA_ADMIN_ADDRESS:8774/v2/\$(tenant_id)s" \
	--internalurl "$PROTOCOL://$NOVA_INTERNAL_ADDRESS:8774/v2/\$(tenant_id)s" \
        nova
fi

#
# Volume service
#
openstack service create --name=cinder \
                         --description="Cinder Volume Service" \
                         volume
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$CINDER_PUBLIC_ADDRESS:8776/v1/\$(tenant_id)s" \
	--adminurl "$PROTOCOL://$CINDER_ADMIN_ADDRESS:8776/v1/\$(tenant_id)s" \
	--internalurl "$PROTOCOL://$CINDER_INTERNAL_ADDRESS:8776/v1/\$(tenant_id)s" \
        volume
 
fi

openstack service create --name=cinderv2 \
                         --description="Cinder Volume Service (Version 2)" \
                         volumev2
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$CINDER_PUBLIC_ADDRESS:8776/v2/\$(tenant_id)s" \
	--adminurl "$PROTOCOL://$CINDER_ADMIN_ADDRESS:8776/v2/\$(tenant_id)s" \
	--internalurl "$PROTOCOL://$CINDER_INTERNAL_ADDRESS:8776/v2/\$(tenant_id)s" \
        volumev2
fi

#
# Image service
#
openstack service create --name=glance \
                         --description="Glance Image Service" \
                         image
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$GLANCE_PUBLIC_ADDRESS:9292" \
	--adminurl "$PROTOCOL://$GLANCE_ADMIN_ADDRESS:9292" \
	--internalurl "$PROTOCOL://$GLANCE_INTERNAL_ADDRESS:9292" \
        glance
fi

#
# EC2 service
#
openstack service create --name=ec2 \
                         --description="EC2 Compatibility Layer" \
                         ec2
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$EC2_PUBLIC_ADDRESS:8773/services/Cloud" \
	--adminurl "$PROTOCOL://$EC2_ADMIN_ADDRESS:8773/services/Admin" \
	--internalurl "$PROTOCOL://$EC2_INTERNAL_ADDRESS:8773/services/Cloud" \
        ec2
fi

#
# Swift service
#
openstack service create --name=swift \
                         --description="Swift Object Storage Service" \
                         object-store
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$SWIFT_PUBLIC_ADDRESS:8080/v1/AUTH_\$(tenant_id)s" \
        --adminurl  "$PROTOCOL://$SWIFT_ADMIN_ADDRESS:8080/v1" \
        --internalurl "$PROTOCOL://$SWIFT_INTERNAL_ADDRESS:8080/v1/AUTH_\$(tenant_id)s"  \
        swift
fi

#
# Neutron service
#
openstack service create --name=neutron \
                         --description="Neutron Network Service" \
                         network
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
        --publicurl   "$PROTOCOL://$NEUTRON_PUBLIC_ADDRESS:9696" \
        --adminurl    "$PROTOCOL://$NEUTRON_ADMIN_ADDRESS:9696" \
        --internalurl "$PROTOCOL://$NEUTRON_INTERNAL_ADDRESS:9696" \
        neutron
fi

#
# Heat service
#
openstack service create --name=heat-cfn \
                         --description="Heat CloudFormation API" \
                         cloudformation
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$HEAT_CFN_PUBLIC_ADDRESS:8000/v1" \
	--adminurl "$PROTOCOL://$HEAT_CFN_ADMIN_ADDRESS:8000/v1" \
	--internalurl "$PROTOCOL://$HEAT_CFN_INTERNAL_ADDRESS:8000/v1" \
        heat-cfn
fi

openstack service create --name=heat \
                         --description="Heat API" \
                         orchestration
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "$PROTOCOL://$HEAT_PUBLIC_ADDRESS:8004/v1/\$(tenant_id)s" \
	--adminurl "$PROTOCOL://$HEAT_ADMIN_ADDRESS:8004/v1/\$(tenant_id)s" \
	--internalurl "$PROTOCOL://$HEAT_INTERNAL_ADDRESS:8004/v1/\$(tenant_id)s" \
        heat
fi 

#
# Ironic service
#
# Kilo Ironic does not support SSL/TLS endpoint
# so we leave it http here.
openstack service create --name=ironic \
    --description="Ironic Bare Metal Provisioning Service" \
    baremetal
if [[ -z "$DISABLE_ENDPOINTS" ]]; then
    openstack endpoint create --region $REGION_NAME \
	--publicurl "http://$IRONIC_PUBLIC_ADDRESS:6385" \
	--adminurl "http://$IRONIC_ADMIN_ADDRESS:6385" \
	--internalurl "http://$IRONIC_INTERNAL_ADDRESS:6385" \
        ironic
fi

# create ec2 creds and parse the secret and access key returned
ADMIN_USER=$(get_id openstack user show admin)
RESULT=$(openstack ec2 credentials create --project ${SERVICE_PROJECT} \
    --user $ADMIN_USER)
ADMIN_ACCESS=`echo "$RESULT" | grep access | awk '{print $4}'`
ADMIN_SECRET=`echo "$RESULT" | grep secret | awk '{print $4}'`

# write the secret and access to ec2rc
cat > $EC2RC <<EOF
ADMIN_ACCESS=$ADMIN_ACCESS
ADMIN_SECRET=$ADMIN_SECRET
EOF
