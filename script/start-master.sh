#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
DOCKM_HOME=$(dirname "${SCRIPTPATH}")

source "${DOCKM_HOME}/script/common.sh"

log_info "Running start script"

function load_dockm_image(){
    docker load -i /opt/dockm/image/click2cloud-dockm-new.tar

    docker load -i /opt/dockm/image/prometheus.tar
}

function check_dockm_image(){
    docker_images=$(docker images)
    log_info "$docker_images"
}

USERDATA_FOLDER="/data/var/lib/docker/volumes/userdata"
mkdir -p $USERDATA_FOLDER
 
function run_dockm_image(){
docker service create \
    --name click2cloud-dockm \
    --replicas 1 \
    --publish 9000:9000 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --mount type=bind,src=$USERDATA_FOLDER,dst=/click2cloud-dockm/data \
     click2cloud/dockm:new \
    -H unix:///var/run/docker.sock \
    -l name="Click2Cloud DockM" 


}

CERT_EXPIRY="17520h0m0s"
function docker_init_swarm(){
    retry docker swarm init --cert-expiry ${CERT_EXPIRY} &>/dev/null
    echo "exit code: $?"
}


function run_prometheus_service(){
docker service create \
    --name my-prometheus \
    --replicas 1 \
    --mount type=bind,source=/etc/prometheus.yml,destination=/etc/prometheus/prometheus.yml \
    --publish published=9090,target=9090,protocol=tcp \
    --constraint 'node.role == manager' \
    prom/prometheus
}







function delete_existed_promethus_container(){
 docker rm $(docker ps --all -f status=exited | awk '{ print $1,$2 }' | grep prom/prometheus)
}


 

log_info "Starting docker engine"
docker_start


isSwarmNode
swarm_ready=$?
if [ "$swarm_ready" == 0 ]
then
echo "Initialize swarm manager"

# Initialize Docker Swarm Manager
log_info "Running docker swarm init command"
docker_init_swarm
log_info "docker swarm init sucessfully.."
log_info "Loading DockM Image"
load_dockm_image

log_info "Checking DockM Image"
check_dockm_image

log_info "Running DockM Image"
run_dockm_image

log_info "Run prometheus service"
run_prometheus_service





else
     echo "Already in  swarm mode "
     log_info "Delete Exited promethues service container"
     delete_existed_promethus_container

fi





log_info "Exiting start script"
                                  


















