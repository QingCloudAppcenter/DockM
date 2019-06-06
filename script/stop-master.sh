#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
DOCKM_HOME=$(dirname "${SCRIPTPATH}")

source "${DOCKM_HOME}/script/common.sh"

log_info "Running stop script"

docker_stop_rm_all
docker_stop

log_info "Exiting stop script"
