#!/bin/bash

#read -p "Enter number of elasticsearch nodes: " NODES

#if [[ -n ${NODES//[0-9]/} ]]
#then
#    echo "Please enter a numeric value!"
#    exit
#elif [[ $NODES == 0 ]]
#then
#    echo "Nodes should be atleast 1"
#    exit
#fi
read -p "Enter password for certificate: " -s PASSWORD
echo

# Generate Root Key rootCA.key with 2048
openssl genrsa -passout pass:"$PASSWORD" -des3 -out rootCA.key 2048

# Generate Root PEM (rootCA.pem) with 10240 days validity.
openssl req -passin pass:"$PASSWORD" -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=Local Certificate"  -x509 -new -nodes -key rootCA.key -sha256 -days 10240 -out rootCA.pem

# Add root cert as trusted cert
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        yum -y install ca-certificates
        update-ca-trust force-enable
        cp rootCA.pem /etc/pki/ca-trust/source/anchors/
        update-ca-trust
        #meeting ES requirement
        sysctl -w vm.max_map_count=262144
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem
else
        # Unknown.
        echo "Couldn't find desired Operating System. Exiting Now ......"
        exit 1
fi

#if [[ $NODES == 1 ]]
#then
    # Generate elasticsearch Cert
openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out elasticsearch.csr -newkey rsa:2048 -keyout elasticsearch.key

openssl x509 -req -passin pass:"$PASSWORD" -in elasticsearch.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out elasticsearch.crt -days 10240 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:elasticsearch")
#else
    #for ((i=1; i<=$NODES; i++))
    #do
        #openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out elasticsearch-$i.csr -newkey rsa:2048 -keyout elasticsearch-$i.key
        
        #openssl x509 -req -passin pass:"$PASSWORD" -in elasticsearch-$i.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out elasticsearch-$i.crt -days 10240 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:elasticsearch-$i")
#    done
#fi

# Generate kibana Cert
openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out kibana.csr -newkey rsa:2048 -keyout kibana.key

openssl x509 -req -passin pass:"$PASSWORD" -in kibana.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out kibana.crt -days 10240 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:kibana")