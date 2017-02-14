#!/bin/bash
# Test case for kompose up/down

LOG_FILE=$1
source ./lib.sh

create_log "[KOMPOSE] Running redis compose file: tests/redis/docker-compose.yml"
kompose --provider=openshift -f tests/redis/docker-compose.yml up &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose command failed"
    exit 1;
fi

create_log "Waiting for the pods to come up"

# TODO: fix this
sleep 200;

if [ $(oc get pods | grep redis | awk '{ print $3 }') == 'Running'  ] &&
       [ $(oc get pods | grep web | awk '{ print $3 }') == 'Running'  ] ; then
    create_log "[KOMPOSE] All pods are Running"
    oc get pods >> $LOG_FILE
fi

# Kompose down
kompose --provider=openshift -f tests/redis/docker-compose.yml down &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose down command failed"
    exit 1;
fi

sleep 200;

if [ $(oc get pods | wc -l ) == 0 ] ; then
    create_log "[KOMPOSE] All pods are down"
    exit 0;
fi
