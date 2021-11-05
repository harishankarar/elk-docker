Environment Details
-------------------
This docker-compose project will create the following Elastic containers based on version 7.15.0:

- Elasticsearch
- Logstash
- Kibana

Note: Logstash has been disabled in docker-compose.yml. To enable it, remove profiles section under logstash service.
    
    profiles:
      - donotstart


Prerequsite
-----------
You might get the following error. So, before proceeding with docker compose we need to set "vm.max_map_count" to "262144".

ERROR: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

To make it persistent, you can add this line:
~# vi /etc/sysctl.conf
vm.max_map_count=262144

~# sysctl -p


Extract the archive
-------------------
Explore to the directory where the tarball is downloaded

~# cd /path/to/tar/ball
~# tar -xzf elk-docker.tar.gz


Contents of ELK-Docker Directory
--------------------------------
- elasticsearch/
  - Dockerfile
  - config/
    - elasticsearch.yml
- elkcerts/
  - certgen.sh
- kibana/
  - Dockerfile
  - config/
    - kibana.yml
- logstash/
  - Dockerfile
  - config/
    - losgtash.yml
  - pipeline/
    - losgtash.conf
- docker-compose.yml
- docker-stack.yml
- .env
- README.md


To create Certificates
----------------------
This automation will generate self-signed certificates for localhost using OpenSSL, add root cert to the trusted list and spin Elasticserch and Kibana containers with SSL implemented.

~# cd elkcerts
~# ./certgen.sh


Contents after running the script
---------------------------------
- elasticsearch.crt
- elasticsearch.csr
- elasticsearch.key
- kibana.crt
- kibana.csr
- kibana.key
- rootCA.key
- rootCA.pem
- rootCA.srl

keep the certificates safe.

Now we are ready to create the elasticsearch and kibana containers.


To create elasticsearch and kibana containers
---------------------------------------------
~# cd /path/to/elk_docker

~# docker-compose up -d

~# docker-compose ps

Once deployed, you can visit kibana with the below link.

https://localhost:6601


Errors:
------
~# docker-compose up -d
Creating network "elk-docker_elastic" with driver "bridge" ERROR: Failed to Setup IP tables: Unable to enable SKIP DNAT rule:  (iptables failed: iptables --wait -t nat -I DOCKER -i br-2b5916a7b664 -j RETURN: iptables: No chain/target/match by that name.  (exit status 1))

Solution:
Something has deleted the docker iptables entries. Docker will recreate them if you restart it (systemctl restart docker). You'll want to disable anything else that manages iptables to prevent this from happening in the future.

~# systemctl restart docker


To stop elk-docker
------------------
~# docker-compose down


To stop elk-docker and to remove volumes
----------------------------------------
~# docker-compose down -v 


To restart elk-docker
---------------------
~# docker-compose restart

we can also restart individual containers.
~# docker-compose restart <service_name>

eg:
~# docker-compose restart elasticsearch


To check elk-docker logs
------------------------
~# docker-compose logs -f <service_name>

eg:
~# docker-compose logs -f elasticsearch


Troubleshooting a container
---------------------------
To trouble shoot a container we might need to access the container's shell. This can be achieved by the following steps.

Method 1:
~# docker container ps              ==> (to get the container name or id)
~# docker exec --detach-keys="ctrl-d" -it <CONTAINER_NAME/ID> bash

Method 2:
~# cd /opt/installer/elk-docker
~# docker-compose exec <service_name> bash

Note: To quit the interactive shell, press ctrl+d.


<--------------------------------------- Client Config Starts --------------------------------------->

Client Config
-------------

To send log data to elasticsearch from client:

Install filebeat to collect logs from clients:
~# curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.15.0-x86_64.rpm

~# yum install filebeat-7.15.0-x86_64.rpm

~# vim /etc/filebeat/filebeat.yml
filebeat.inputs:
- input_type: log
  paths:
    - /var/log/secure
  fields:
    event.dataset: <SERVERNAME.log_file_name>
  fields_under_root: true
  input_type: log
  document_type: syslog
  registry: /var/lib/filebeat/registry
- input_type: log
  paths:
    - /var/log/messages
  fields:
    event.dataset: <SERVERNAME.log_file_name>
  fields_under_root: true
  document_type: syslog
  registry: /var/lib/filebeat/registry
output.elasticsearch:
  hosts: ["https://<SERVER_IP>:9400"]
  protocol: "https"
  username: "elastic"
  password: "admin@123"
  ssl.verification_mode: certificate
  ssl.certificate_authorities: ["/etc/filebeat/rootCA.pem"]

Note: We need to copy the certificate rootCA.pem to the above mentioned location.

~# systemctl start filebeat

~# systemctl status filebeat


<--------------------------------------- Client Config Ends --------------------------------------->


To view logs
------------

Visit https://<SERVER-IP>:<PORT> from the browser.
To view the Logs app, go to Observability > Logs.
Click Stream Live to view a continuous flow of log messages in real time, or click Stop streaming to view historical logs from a specified time range.


To add rules in elastic UI
--------------------------
We need to create encryption keys in kibana.

~# cd /opt/installer/elk-docker
~# docker-exec kibana bash
bash-4.4$ bin/kibana-encryption-keys generate -i
bash-4.4$ exit

Copy the keys to a separate file outside the container (in your local machine). Also add the below lines to /opt/installer/scripts/elk-docker/kibana/config/kibana.yml

~#  vim /opt/installer/scripts/elk-docker/kibana/config/kibana.yml
xpack.encryptedSavedObjects.encryptionKey: <encryptedSavedObjects_encryptionKey>
xpack.reporting.encryptionKey: <reporting_encryptionKey>
xpack.security.encryptionKey: <security_encryptionKey>

xpack.security.session.idleTimeout: "10m"
xpack.security.session.lifespan: "1h"


Restart kibana to make the changes work
~# cd /opt/installer/elk-docker
~# docker-compose restart kibana
