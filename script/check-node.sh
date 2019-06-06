#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
DOCKM_HOME=$(dirname "${SCRIPTPATH}")

source "${DOCKM_HOME}/script/common.sh"

swarm_ready="false"
docker_ready="false"
if [ $(docker_active) == "active" ]; then
  docker_ready="true"
fi

availability=$(check_docker_node Spec Availability)
status=$(check_docker_node Status State)
    
echo "Status:${status}"
echo "Availability:${availability}"

if [ "${status}" == "ready" ] && [ "${availability}" == "active" ]; then
  swarm_ready="true"
fi

if [ "${docker_ready}" == "true" ] && [ "${swarm_ready}" == "true" ]; then
  exit 0
else
  exit 1
fi
