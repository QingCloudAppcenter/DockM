#!/bin/bash

CLUSTER_INFO="${DOCKM_HOME}/cluster-info"

LOG_FILE="/logs/cluster_logs"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

function log_info { 
    log_common "INFO" "$1"
}

function log_warn {
    log_common "WARN" "$1" 
}

function log_error {
    log_common "ERROR" "$1"
}

function log_common {
    dt=$(date '+%F %T')
    echo "[$1]: $dt $2" &>> ${LOG_FILE}
}

function fail {
    log_error "$1"
    exit 1
}

function retry {
    local COUNTER=1
    local MAX=5
    local delay=5
    while true; do
        "$@" && break || {
            if [[ $COUNTER -lt $MAX ]]; then
                log_info "Command failed. Attempt $COUNTER/$MAX:"
                COUNTER=$[$COUNTER +1]
                sleep $delay;
            else
                fail "The command has failed after $COUNTER attempts."
                break;
            fi
        }
    done
}

function docker_start () {
    retry systemctl start docker
    chmod 666 /var/run/docker.sock
}

function docker_stop () {
    retry systemctl stop docker
}

function docker_restart () {
    retry systemctl restart docker
    chmod 666 /var/run/docker.sock
}

function docker_stop_rm_all () {
    for i in "docker ps -q"
    do
        docker stop $i;
    done
    for i in "docker ps -aq"
    do
        docker rm -f $i;
    done
}

function docker_active(){
    systemctl is-active docker
}

function docker_leave_swarm(){
    retry docker swarm leave --force
}

function check_docker_master(){
    if [  -f "${CLUSTER_INFO}" ]; then
        while IFS=' ' read -r f1 f2 f3; do
            if [ "${f3}" = "master" ]; then
                if [ ! -z "${f2// }" ]; then
                    status=$(docker node inspect --format "{{ .$1.$2  }}" $f2)
                    echo $status
                else
                    break
                fi
            fi
        done < "$CLUSTER_INFO"
   fi
}

SSH_FOLDER="/home/ubuntu/.ssh/"
function check_docker_node(){
    if [  -f "${CLUSTER_INFO}" ]; then
        while IFS=' ' read -r f1 f2 f3; do
            if [ "${f3}" = "node" ]; then
                if [ ! -z "${f2// }" ]; then
                    status=$(ssh -i ${SSH_FOLDER}/id_rsa ubuntu@master "docker node inspect --format '{{ .$1.$2  }}' $f2")
                    echo $status
                else
                    break
                fi
            fi
        done < "$CLUSTER_INFO"
    fi
}

function clean(){
    rm -rf /opt/dockm/image
}


function isSwarmNode(){
    if [ "$(docker info | grep Swarm | sed 's/Swarm: //g')" == "inactive" ]; then
         swarm_ready=0;
        echo "$swarm_ready"
    else
         swarm_ready=1;
       echo "$swarm_ready"
    fi

 return $swarm_ready
}
