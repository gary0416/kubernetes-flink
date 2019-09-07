#!/bin/bash

###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# If unspecified, the hostname of the container is taken as the JobManager address
JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS:-$(hostname -f)}
CONF_FILE="${FLINK_HOME}/conf/flink-conf.yaml"

if [[ $JOB_MANAGER_RPC_ADDRESS == *. ]]; then
    # in k8s, hostname -f is "xxx.cluster.local."
    # but in flink source:Preconditions.checkArgument(!host.endsWith("."))
    # https://github.com/apache/flink/blob/release-1.9.0/flink-core/src/main/java/org/apache/flink/util/NetUtils.java#L153
    echo "$JOB_MANAGER_RPC_ADDRESS is endswith . and against with NetUtils.java:153"
    JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS%?}
    echo "JOB_MANAGER_RPC_ADDRESS now is $JOB_MANAGER_RPC_ADDRESS"
else
    echo "JOB_MANAGER_RPC_ADDRESS is $JOB_MANAGER_RPC_ADDRESS"
fi

# fix sed faild:
# Secret, configMap, downwardAPI and projected volumes will be mounted as read-only volumes
# if template exists,then replace the target
CONF_FILE_TEMPLATE_DIR="${FLINK_HOME}/conf-template"
CONF_DIR="${FLINK_HOME}/conf"
if [[ -d "${CONF_FILE_TEMPLATE_DIR}" ]]; then
    for cfgFile in "${CONF_FILE_TEMPLATE_DIR}"/*
    do
        echo "replacing cfgFile ${cfgFile}"
        cp -f "$cfgFile" "$CONF_DIR/$(basename "$cfgFile")"
    done
fi

drop_privs_cmd() {
    if [ $(id -u) != 0 ]; then
        # Don't need to drop privs if EUID != 0
        return
    elif [ -x /sbin/su-exec ]; then
        # Alpine
        echo su-exec flink
    else
        # Others
        echo gosu flink
    fi
}

if [ "$1" = "help" ]; then
    echo "Usage: $(basename "$0") (jobmanager|taskmanager|help|debug)"
    exit 0
elif [ "$1" = "jobmanager" ]; then
    shift 1
    echo "Starting Job Manager"

    if grep -E "^jobmanager\.rpc\.address:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/jobmanager\.rpc\.address:.*/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "${CONF_FILE}"
    else
        echo "jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}" >> "${CONF_FILE}"
    fi

    if grep -E "^blob\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/blob\.server\.port:.*/blob.server.port: 6124/g" "${CONF_FILE}"
    else
        echo "blob.server.port: 6124" >> "${CONF_FILE}"
    fi

    if grep -E "^query\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/query\.server\.port:.*/query.server.port: 6125/g" "${CONF_FILE}"
    else
        echo "query.server.port: 6125" >> "${CONF_FILE}"
    fi

    echo "config file: " && grep '^[^\n#]' "${CONF_FILE}"
    exec $(drop_privs_cmd) "$FLINK_HOME/bin/jobmanager.sh" start-foreground "$@"
elif [ "$1" = "taskmanager" ]; then
    shift 1
    echo "Starting Task Manager"

    TASK_MANAGER_NUMBER_OF_TASK_SLOTS=${TASK_MANAGER_NUMBER_OF_TASK_SLOTS:-$(grep -c ^processor /proc/cpuinfo)}

    if grep -E "^jobmanager\.rpc\.address:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/jobmanager\.rpc\.address:.*/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "${CONF_FILE}"
    else
        echo "jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}" >> "${CONF_FILE}"
    fi

    if grep -E "^taskmanager\.numberOfTaskSlots:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/taskmanager\.numberOfTaskSlots:.*/taskmanager.numberOfTaskSlots: ${TASK_MANAGER_NUMBER_OF_TASK_SLOTS}/g" "${CONF_FILE}"
    else
        echo "taskmanager.numberOfTaskSlots: ${TASK_MANAGER_NUMBER_OF_TASK_SLOTS}" >> "${CONF_FILE}"
    fi

    if grep -E "^blob\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/blob\.server\.port:.*/blob.server.port: 6124/g" "${CONF_FILE}"
    else
        echo "blob.server.port: 6124" >> "${CONF_FILE}"
    fi

    if grep -E "^query\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/query\.server\.port:.*/query.server.port: 6125/g" "${CONF_FILE}"
    else
        echo "query.server.port: 6125" >> "${CONF_FILE}"
    fi

    echo "config file: " && grep '^[^\n#]' "${CONF_FILE}"
    exec $(drop_privs_cmd) "$FLINK_HOME/bin/taskmanager.sh" start-foreground "$@"
elif [ "$1" = "debug" ]; then
    # debuging
    shift 1
    echo "sleep 1d..."
    sleep 1d
fi

exec "$@"
