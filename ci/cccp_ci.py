# This script uses the Duffy node management api to get fresh machines to run
# your CI tests on. Once allocated you will be able to ssh into that machine
# as the root user and setup the environ
#
# XXX: You need to add your own api key below, and also set the right cmd= line
#      needed to run the tests
#
# Please note, this is a basic script, there is no error handling and there are
# no real tests for any exceptions. Patches welcome!

import json
import os
import urllib
import sys
import re
import requests

from lib import _print, run_cmd, provision
api=open('/home/kompose/duffy.key').read().strip()
# url_base = os.environ.get('URL_BASE')
url_base="http://admin.ci.centos.org:8080"
#api = os.environ.get('API')
ver = "7"
arch = "x86_64"
count = 1

#repo_url = os.environ.get('kompose_tests_github')
repo_url = 'https://github.com/ashetty1/kompose-tests.git'
#repo_branch = os.environ.get('ghprbSourceBranch') or \
#    os.environ.get('ghprbTargetBranch') or 'master'


def get_nodes(ver="7", arch="x86_64", count=4):
    get_nodes_url = "%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (
        url_base, api, ver, arch, count)
    resp = urllib.urlopen(get_nodes_url).read()
    data = json.loads(resp)
    with open('env.properties', 'a') as f:
        f.write('DUFFY_SSID=%s' % data['ssid'])
        f.close()
    _print(resp)
    return data['hosts']


# def fail_nodes():
#     with open('env.properties') as f:
#         s = f.read()

#     ssid = None
#     for line in s.splitlines():
#         key, value = line.split('=')
#         if key == 'DUFFY_SSID':
#             ssid = value
#             break

#     fail_nodes_url = "{url_base}/Node/fail?key={key}&ssid={ssid}".format(
#         url_base=url_base, key=api, ssid=ssid)
#     resp = urllib.urlopen(fail_nodes_url).read()
#     _print(resp)
 

# def print_nodes():
#     with open('env.properties') as f:
#         s = f.read()

#     _print('\n'.join(s.splitlines()[3:]))


        
def setup_controller(controller):
    # provision controller
    run_cmd("yum install -y git &&"
             "yum install -y gcc libffi-devel python-devel openssl-devel && "
             "yum install -y docker && "
             "yum install -y golang && "
             "yum install -y python-requests",
             host=controller, stream=True)

    #run_cmd("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
    #        "root@%s 'yum -y install git'" % controller)

    
    run_cmd("scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
            "docker_settings.sh root@%s:/tmp" % controller, stream=True)
    
    run_cmd("/tmp/docker_settings.sh", host=controller, stream=True)


def kompose_setup(controller):
    _print("Installing the kompose binary on the controller")
    run_cmd("export GOPATH=/usr && go get github.com/kubernetes-incubator/kompose", host=controller)
    
    _print("Installing the oc binaries on the controller")
    oc_download_url = requests.get("https://api.github.com/repos/openshift/origin/releases/latest").json()['assets'][2]['browser_download_url']
    run_cmd("yum install wget -y", host=controller)
    run_cmd("wget " + oc_download_url + " -O /tmp/oc.tar.gz",
            host=controller)
    run_cmd("mkdir /tmp/ocdir && cd /tmp/ocdir && tar -xvvf /tmp/oc.tar.gz",
            host=controller)
    run_cmd("cp /tmp/ocdir/*/oc /usr/bin/", host=controller)
    run_cmd("service docker restart", host=controller)
    run_cmd("service docker status", host=controller)
    

def host_clean_up(controller):
    run_cmd("rm -rf /usr/bin/kompose && rm -rf /tmp/kompose-tests",
            host=controller)
    
    
def run():
    nodes = get_nodes(count=1)

    controller = nodes[0]
    
    setup_controller(controller)
    kompose_setup(controller)
    run_cmd('iptables -F', host=controller)

    run_cmd('git clone ' + str(repo_url) + ' /tmp/kompose-tests/',
            host=controller) 
    run_cmd('cd /tmp/kompose-tests/ && ./run.sh',
            host=controller, stream=True)


if __name__ == '__main__':
    try:
        run()
    except Exception as e:
        _print('Build failed: %s' % e)
        _print('Reserving nodes for debugging...')
        # fail_nodes()
        #_print('=' * 10 + 'Node Info' + '=' * 10)
        #print_nodes()
        sys.exit(1)
