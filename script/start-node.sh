#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
DOCKM_HOME=$(dirname "${SCRIPTPATH}")

source "${DOCKM_HOME}/script/common.sh"

log_info "Running start script"

SSH_FOLDER="/home/ubuntu/.ssh/"
function docker_join_swarm(){
    token_result=$(ssh -i ${SSH_FOLDER}/id_rsa ubuntu@master "docker swarm join-token worker")
    log_info "${token_result}"
    while IFS=':' read -ra STR; do
      for s in "${STR[@]}"; do
        if [[ "$s" = *"docker swarm join"* ]]; then
            cmd="$s"
        fi
      done
    done <<< "$token_result"

    swarm_join_cmd="$cmd:2377"
    log_info "${swarm_join_cmd}"
    $swarm_join_cmd
}

function check_node_swarm_state(){
    state=$(docker info -f "{{json .Swarm.LocalNodeState}}" | sed -e 's/^"//' -e 's/"$//')
}

log_info "Starting docker service"
docker_start

# Initialize Docker Swarm Worker
log_info "Joining docker swarm cluster"
docker_join_swarm

#check_node_swarm_state
#if [ "$state" == "inactive" ]; then
#    log_info "Joining docker swarm cluster"
#    docker_join_swarm
#fi

clean
log_info "Exiting start script"
