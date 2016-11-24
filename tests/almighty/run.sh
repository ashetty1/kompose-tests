#!/bin/sh

# Test case for almighty

LOG_FILE=$1
source ./lib.sh

create_log "[KOMPOSE] Running almighty compose file: tests/almighty/docker-compose.yml"
kompose --provider=openshift -f tests/almighty/docker-compose.yml up &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose command failed"
    exit;
fi

create_log "[ALMIGHTY] Waiting for the pods to come up"

# TODO: fix this
sleep 200;

if [ $(oc get pods | grep core | awk '{ print $3 }') == 'Running'  ] &&
       [ $(oc get pods | grep db | awk '{ print $3 }') == 'Running'  ] ; then
    create_log "[ALMIGHTY] All Almighty pods are Running"
    oc get pods >> $LOG_FILE
fi

# Expose the service as a route
oc expose svc/core
route_url=`oc get route core | grep xip | awk '{ print $2 }'`
create_log "[ALMIGHTY] svc/core exposed"
create_log "[ALMIGHTY] URL to access core: ${route_url}"


# TODO: Check if the db and web are talking to each other

