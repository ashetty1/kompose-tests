
# Unsupported Kompose labels
# https://github.com/kubernetes-incubator/kompose/blob/master/docs/user-guide.md#unsupported-docker-compose-configuration-options
KOMPOSE_UNSUPPORTED="build cgroup_parent devices depends_on dns dns_search domainname env_file extends external_links extra_hosts hostname ipc logging mac_address mem_limit memswap_limit network_mode networks pid security_opt shm_size stop_signal volume_driver uts read_only stdin_open tty user ulimits dockerfile net"

check_support() {
    local compose_file=$1
    K_US=`grep -s ${KOMPOSE_UNSUPPORTED} ${compose_file} | wc -l`

    if [ $K_US -gt 0 ]; then
	create_log "${1} contains unsupported docker-compose configuration options"
	exit 1;
    fi
}

# Logging function
create_log() {
    echo `date "+%Y-%m-%d %H:%M:%S"` $1 >> $LOG_FILE;
    echo $1;
}


# To create PVs for volume mounts
create_pv() {

    local nfs_server=$1
    local nfs_path=$2

    cp ./create_pv.yaml /tmp/create_pv_tmp.yaml
    # Using < as the delimiter
    sed -i 's<path: /data<path: ${nfs_path}<g' /tmp/create_pv_tmp.yaml
    sed -i 's<path: /data<path: ${nfs_path}<g' /tmp/create_pv_tmp.yaml

    oc create -f /tmp/create_pv_tmp.yaml
    sleep 5;
    pv_status=`oc get pv | grep pv0001 | awk '{ print $4 }'`
    create_log "PV ${pv_name} status: ${pv_status}"
    if [ $pv_status == 'Available' ]; then
	return 0
    fi
}

os_cleanup() {
    # routes
    oc delete dc,svc,is,pvc,pods,routes --all
}
