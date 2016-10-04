#!/usr/bin/python

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

#
# Creates Root CA, Intermediate CA and Node Server/Client keys
#

import os
import sys
import platform
import shutil
import decimal
from subprocess import CalledProcessError, Popen, PIPE, check_call, call

CERT_COUNTRY = "US"
CERT_STATE = "New York"
CERT_CITY = "New York"
CERT_COMPANY = "OracleTest"
CERT_ORG = "ExampleOrg"

ROOT_CA_CN = "OracleOSPOCRoot"
INTERMEDIATE_CA_CN = "OracleOSPOCInt"

SERVER_CERT_COUNTRY = "US"
SERVER_CERT_STATE = "New York"
SERVER_CERT_CITY = "New York"
SERVER_CERT_COMPANY = "OracleTest"
SERVER_CERT_ORG = "ExampleOrg"

KEYS_DIR = "./keys"

KEYS_ROOT_CAKEY = KEYS_DIR + "/private/" + "ca.key.pem"
KEYS_ROOT_CACERT = KEYS_DIR + "/certs/" + "ca.cert.pem"

KEYS_INTER_DIR = KEYS_DIR + "/intermediate"
KEYS_INTER_CAKEY = KEYS_INTER_DIR + "/private/" + "intermediate.key.pem"
KEYS_INTER_CSR = KEYS_INTER_DIR + "/csr/" + "intermediate.csr.pem"
KEYS_INTER_CERT = KEYS_INTER_DIR + "/certs/" + "intermediate.cert.pem"

KEYS_CA_CHAIN = KEYS_INTER_DIR + "/certs/" + "ca-chain.cert.pem"

#RAND_FILE = "${HOME}/.rnd"
RAND_FILE = "keys/private/.rand"

# creates the root certificate pair to sign with
def create_root_ca_pair():
    # Create temp paths
    if not os.path.exists("%s/certs" % KEYS_DIR):
        os.makedirs("%s/certs" % KEYS_DIR, 0755)
    if not os.path.exists("%s/crl" % KEYS_DIR):
        os.makedirs("%s/crl" % KEYS_DIR, 0755)
    if not os.path.exists("%s/newcerts" % KEYS_DIR):
        os.makedirs("%s/newcerts" % KEYS_DIR, 0755)
    if not os.path.exists("%s/private" % KEYS_DIR):
        os.makedirs("%s/private" % KEYS_DIR, 0700)

    f = open("%s/serial" % KEYS_DIR, 'w')
    ser = "1"
    ser = ser.zfill(2)
    f.write("%s\n" % ser)
    f.close()

    open("%s/index.txt" % KEYS_DIR, 'a').close()
    
    # Generate the root CA key
    check_call(["openssl", "genrsa", "-out", KEYS_ROOT_CAKEY, "4096"],
            env={"RANDFILE": RAND_FILE})
    check_call(["chmod", "0400", KEYS_ROOT_CAKEY])

    subj = "/C=%s/ST=%s/L=%s/O=%s/CN=%s" % (CERT_COUNTRY,
        CERT_STATE, CERT_CITY, CERT_COMPANY,
        ROOT_CA_CN)

    # Generate the root certificate
    check_call(["openssl", "req", "-config", "openssl.cnf", "-key",
        KEYS_ROOT_CAKEY, "-new", "-x509", "-days", "3650", "-sha256",
        "-extensions", "v3_ca", "-subj", subj, "-out", KEYS_ROOT_CACERT],
        env={"SAN": "DNS:" + ROOT_CA_CN,
             "RANDFILE": RAND_FILE})
    check_call(["chmod", "0444", KEYS_ROOT_CACERT])

def create_root_ca_intermediate_pair():
    # Create temp paths
    i_path = KEYS_DIR + "/intermediate"
    if not os.path.exists(i_path):
        os.makedirs(i_path, 0755)
    if not os.path.exists(i_path + "/certs"):
        os.makedirs(i_path + "/certs", 0755)
    if not os.path.exists(i_path + "/crl"):
        os.makedirs(i_path + "/crl", 0755)
    if not os.path.exists(i_path + "/csr"):
        os.makedirs(i_path + "/csr", 0755)
    if not os.path.exists(i_path + "/newcerts"):
        os.makedirs(i_path + "/newcerts", 0755)
    if not os.path.exists(i_path + "/private"):
        os.makedirs(i_path + "/private", 0700)

    f = open(i_path + "/serial", 'w')
    ser = "2"
    ser = ser.zfill(2)
    f.write("%s\n" % ser)
    f.close()
    open(i_path + "/index.txt", 'a').close()
    
    # Keeps track of revocation list
    f = open(i_path + "/crlnumber", 'w')
    f.write("%s\n" % ser)
    f.close()
    
    # Generate the intermediate CA key
    check_call(["openssl", "genrsa", "-out", KEYS_INTER_CAKEY, "4096"])
    check_call(["chmod", "0400", KEYS_INTER_CAKEY])

    subj = "/C=%s/ST=%s/L=%s/O=%s/OU=%s/CN=%s" % (CERT_COUNTRY,
        CERT_STATE, CERT_CITY, CERT_COMPANY,
        CERT_ORG, INTERMEDIATE_CA_CN)

    # Generate the intermediate CA CSR
    check_call(["openssl", "req", "-config", "openssl-i.cnf", "-new",
        "-sha256", "-key", KEYS_INTER_CAKEY, "-subj", subj,
        "-out", KEYS_INTER_CSR],
        env={"SAN": "DNS:" + INTERMEDIATE_CA_CN,
             "RANDFILE": RAND_FILE})  
    
    # Generate intermediate CA certificate using root CA to sign it
    check_call(["openssl", "ca", "-batch", "-config", "openssl.cnf", "-extensions",
        "v3_intermediate_ca", "-days", "3650", "-notext", "-md", "sha256",
        "-in", KEYS_INTER_CSR, "-out", KEYS_INTER_CERT],
        env={"SAN": "DNS:" + INTERMEDIATE_CA_CN,
             "RANDFILE": RAND_FILE})

    check_call(["chmod", "0445", KEYS_INTER_CERT])
 
    # Verify intermediate cert against root cert
    check_call(["openssl", "verify", "-CAfile", KEYS_ROOT_CACERT,
        KEYS_INTER_CERT])

# When an app (browser) tries to verify a cert signed by the intermediate
# CA, it must also verify the intermediate CA against the root cert.  To
# complete the chain of trust, create A CA cert chain to present to the app.
def create_cert_chain_file():
    cmd = ['cat', KEYS_INTER_CERT, KEYS_ROOT_CACERT]
    with open(KEYS_CA_CHAIN, "w") as outfile:
        call(cmd, stdout=outfile)
    
# Use intermediate CA to sign certs.  This assume we are the CA
# A third party can instead create their own private key and
# CSR without revealing their private key to you.  They give you their
# CSR and you give back a signed certificate
def sign_cert(cn, keytype, alt_names=""):
    if keytype == "server":
        kext = "server_cert"
        #subj_alt_name = "DNS:%s" % cn
        subj_alt_name = alt_names
    elif keytype == "client":
        kext = "usr_cert"
        subj_alt_name = "otherName:1.2.3.4;UTF8:%s" % cn

    # Deploy
    nkey_path = KEYS_INTER_DIR + "/private/" + cn + "-" + keytype + ".key.pem"
    ncert_path = KEYS_INTER_DIR + "/certs/" + cn + "-" + keytype + ".cert.pem"
    ncert_fchain_path = KEYS_INTER_DIR + "/certs/" + cn + "-" + keytype + "-" + "fchain" + ".cert.pem"

    ncsr_path = KEYS_INTER_DIR + "/csr/" + cn + ".csr.pem"

    i_path = KEYS_DIR + "/intermediate"

    open(i_path + "/index.txt", 'a').close()
    
    # Generate private key
    check_call(["openssl", "genrsa", "-out", nkey_path, "2048"],
            env={"RANDFILE": RAND_FILE})
    check_call(["chmod", "0400", nkey_path])

    # Generate CSR using private key
    # CN must be FQDN for server and anything for client
    subj = "/C=%s/ST=%s/L=%s/O=%s/OU=%s/CN=%s" % (CERT_COUNTRY,
        CERT_STATE, CERT_CITY, CERT_COMPANY,
        SERVER_CERT_ORG, cn)
    check_call(["openssl", "req", "-config", "openssl-i.cnf", "-key",
        nkey_path, "-new", "-sha256",
        "-subj", subj, "-out", ncsr_path],
        env={"SAN": subj_alt_name,
             "RANDFILE": RAND_FILE})

    # Generate a certificate using intermediate CA to sign CSR
    check_call(["openssl", "ca", "-batch", "-config", "openssl-i.cnf", "-extensions",
        kext, "-days", "375", "-notext", "-md", "sha256", "-in",
        ncsr_path, "-out", ncert_path],
        env={"SAN": subj_alt_name,
             "RANDFILE": RAND_FILE})
    check_call(["chmod", "0444", ncert_path])

    # Create full chain with cert
    cmd = ['cat', ncert_path, KEYS_ROOT_CACERT, KEYS_INTER_CERT]
    with open(ncert_fchain_path, "w") as outfile:
        call(cmd, stdout=outfile)

    # Verify the chain of trust
    check_call(["openssl", "verify", "-CAfile", KEYS_CA_CHAIN, ncert_path])

def init_keytree():
    if os.path.exists(RAND_FILE):
        os.remove(RAND_FILE)

    if os.path.exists(KEYS_DIR):
        shutil.rmtree(KEYS_DIR)
    else:
        os.makedirs(KEYS_DIR, 0755)

def main(args):
    if os.path.exists(KEYS_DIR):
        shutil.rmtree(KEYS_DIR)
    else:
        os.makedirs(KEYS_DIR, 0755)
    create_root_ca_pair()
    create_root_ca_intermediate_pair()
    create_cert_chain_file()
    
    # Alt names are required
    alt_names = "DNS.1:serverone,DNS.2:serverone.company.com"
    # Server cert
    sign_cert("serverone.company.com", "server", alt_names)
    # Client cert
    sign_cert("servertwo.company.com", "client")

if __name__ == "__main__":
    main(sys.argv[1:])
