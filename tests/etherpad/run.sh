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

# sleep 200;

while [ "$(oc get pods | grep etherpad | awk '{ print $3 }')" != 'Running'  ] &&
	  [ "$(oc get pods | grep mariadb | awk '{ print $3 }')" != 'Running'  ] ; do
    create_log "Waiting for the pods to come up ..."
    sleep 30;
done

sleep 5;

if [ "$(oc get pods | grep etherpad | awk '{ print $3 }')" == 'Running'  ] &&
       [ "$(oc get pods | grep mariadb | awk '{ print $3 }')" == 'Running'  ] ; then
    create_log "[KOMPOSE] All pods are Running now"
    oc get pods >> $LOG_FILE
fi

# Kompose down

kompose --provider=openshift -f tests/etherpad/docker-compose.yml down &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose down command failed"
    exit 1;
fi

#sleep 200;

while [ $(oc get pods | wc -l ) != 0 ] ; do
    create_log "Waiting for the pods to be deleted ..."
    sleep 30;
done

if [ $(oc get pods | wc -l ) == 0 ] ; then
    create_log "[KOMPOSE] All pods are down now"
    exit 0;
fi
