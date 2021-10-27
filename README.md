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

~# docker container ps      ==> (to get the container name or id)

~# docker exec --detach-keys="ctrl-d" -it <CONTAINER_NAME/ID> bash

~# docker-compose exec <service_name> bash

Note: To quit the interactive shell, press ctrl+d.




<--------------------------------------- Client Config --------------------------------------->

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
  ssl.verification_mode: none

~# systemctl start filebeat

~# systemctl status filebeat
