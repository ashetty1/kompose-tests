#!/bin/sh

source ./config.sh
source ./lib.sh

verify_kompose_up() {
    retry=0;
    while [ $retry -lt 10 ]; do
	sleep 60;
	if [ $retry -gt 0 ]; then
	    create_log "Waiting for the pods to come up ... retry #${retry}"
	fi
	pod_not_run=`oc get pods --no-headers=true | awk '{ print $3 }' | awk '!/Running/' | wc -l`
	pod_crash=`oc get pods --no-headers=true | awk '{ print $3 }' | awk '!/CrashLoopBackOff/' | wc -l`

	if [ $pod_not_run -eq 0 ] ; then
	    create_log "All pods running"
	    return 0;
	fi
	retry=$[$retry+1]
    done
    create_log "Error bringing up pods"
    exit 1;
}

verify_replica_pods() {
    num_pods=$1;
    num_replica=$2;
    total_pods=$(( num_pods*num_replica ))

    get_pods=`oc get rc --no-headers=true | wc -l`
    get_replica=`oc get pods --no-headers=true | wc -l`

    if [ $get_pods -eq $num_replica ]  && [ $get_replica -eq $total_pods ]; then
	create_log "All replicas are up"
	return 0;
    else
	create_log "ERROR: All replicas not up"
	return 1;
    fi

}


test_cli_args() {

    if [ -z $1 ]; then
	create_log "Please provide the docker-compose file to be tested"
	exit;
    fi

    docker_compose_file=$1;


    os_cleanup;
    oc login -u developer -p developer > /dev/null;
    create_log "Test 1: Running with replicas 3"
    mkdir -p test_1; cd test_1;
    # TODO: Create a pv
    kompose --provider=openshift -f $docker_compose_file convert --replicas 3;
    cd ..;
    for i in test_1/*.json; do oc create -f $i; done
    verify_kompose_up; kompose_pod_up=$?;
    # Testing replication
    if [ $kompose_pod_up -eq 0 ]; then
	verify_replica=$(verify_replica_pods 3 3)

	if [ $verify_replica -gt 0 ]; then
	    create_log "Test 1: Running with replicas 3: FAIL"
	else
	    create_log "Test 1: Running with replicas 3: PASS"
	fi
    fi

    sleep 10;

    os_cleanup;
    create_log "Test 2: Running Kompose with emptyvols"
    mkdir test_2; cd test_2;
    kompose --provider=openshift -f $docker_compose_file convert --replicas 3 --emptyvols;
    cd ..;
    for i in test_2/*.json; do oc create -f $i; done
    verify_kompose_up; kompose_pod_up=$?;

    if [ $kompose_pod_up -eq 0 ]; then
	create_log "Test 2: Running Kompose with emptyvols: PASS"
    fi

    sleep 10;

    os_cleanup;
    create_log "Test 3: Redirecting to files"
    kompose --provider=openshift -f $docker_compose_file convert --replicas 3 -o test3_kompose_out
    oc create -f test3_kompose_out;
    verify_kompose_up; kompose_pod_out=$?;
    if [ $kompose_pod_up -eq 0 ]; then
	create_log "Test 3: Running Kompose with -o: PASS"
    fi

    sleep 10
    os_cleanup;
    create_log "Test 4: Validating yaml artifacts with Kompose convert"
    mkdir test_4; cd test_4;
    kompose --provider=openshift -f $docker_compose_file convert -y;
    cd ..;
    for i in test_4/*.yaml; do oc create -f $i; done
    verify_kompose_up; kompose_pod_out=$?;
    if [ $kompose_pod_up -eq 0 ]; then
	create_log "Test 4: Validating yaml artifacts with Kompose convert: PASS"
    fi
}


#test_cli_args docker-compose.yml
