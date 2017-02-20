#!/bin/bash
# Test case for kompose up/down

LOG_FILE=$1
source ./lib.sh

create_log "[KOMPOSE] Running etherpad compose file: tests/etherpad/docker-compose.yml"

export $(cat tests/etherpad/envs)
kompose --provider=openshift -f tests/etherpad/docker-compose.yml up &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose command failed"
    exit 1;
fi

create_log "Waiting for the pods to come up"

# TODO: fix this
# sleep 200;


while [ $(oc get pods | grep etherpad | awk '{ print $3 }') != 'Running'  ] &&
	  [ $(oc get pods | grep mariadb | awk '{ print $3 }') != 'Running'  ] ; do
    create_log "Waiting for the pods to come up ..."
    sleep 50;
done

if [ $(oc get pods | grep etherpad | awk '{ print $3 }') == 'Running'  ] &&
       [ $(oc get pods | grep mariadb | awk '{ print $3 }') == 'Running'  ] ; then
    create_log "[KOMPOSE] All pods are Running"
    oc get pods >> $LOG_FILE
fi

# while [ $(oc get pods | grep etherpad | awk '{ print $3 }') != 'Running'  ] && 
# 	  [ $(oc get pods | grep mariadb | awk '{ print $3 }') != 'Running'  ] ; do
#     create_log "Waiting for the pods to come up ..."
#     sleep 50
# done

# Kompose down

kompose --provider=openshift -f tests/etherpad/docker-compose.yml down &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose down command failed"
    exit 1;
fi

sleep 200;

if [ $(oc get pods | wc -l ) == 0 ] ; then
    create_log "[KOMPOSE] All pods are down"
    exit 0;
fi
