# Test case for almighty

LOG_FILE=$1
source ./lib.sh

create_log "[KOMPOSE] Running almighty compose file: tests/almighty/docker-compose.yml"
kompose --provider=openshift -f tests/almighty/docker-compose.yml up &>> $LOG_FILE; result=$?;

if [ $result -ne 0 ]; then
    create_log "Kompose command failed"
    exit 1;
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


# Check if the db and web are talking to each other
# Sleep to add some delay before probing
sleep 50;
almighty_status=`curl -I http://${route_url}/api/status  2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [ $almighty_status != 200 ]; then
    echo $almighty_status
    create_log "[ALMIGHTY] DB and Core not talking"
    exit 1;
else
    create_log "[ALMIGHTY] Status works"
fi
