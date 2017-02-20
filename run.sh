#!/bin/bash

source ./config.sh
source ./lib.sh

######

starttime=`date "+%Y-%m-%d %H:%M:%S"`
create_log "STARTING TESTS ${starttime}" 
testcases_dir='tests/*'
run_specific_tests='tests/etherpad'

# make sure flush iptables on host
#sudo iptables -F

create_log "Starting oc cluster"
# oc cluster up >> $LOG_FILE; result=$?
# if [ $result -ne 0 ]; then
#     create_log "FAILED: Please check if the 'oc cluster' has been installed."
#     exit;
# fi

oc cluster up;

if [ $result -ne 0 ]; then
    create_log "FAILED 'oc cluster up'"
    results=1
    exit;
fi


if [ $run_specific_tests -ne 0 ]; then
    tests_to_run=$run_specific_tests
else
    tests_to_run=$testcases_dir
fi


for test_case in $tests_to_run ; do
    timeout 30m $test_case/run.sh $LOG_FILE; result=$?

    if [ $result -ne 0 ] ; then
        create_log "FAILED $test_case"
	results=1
	exit;
    else
	create_log "PASSED $test_case"
	create_log "CLEANUP $test_case"
	os_cleanup
    fi

done

create_log "Bringing down oc cluster"
oc cluster down
