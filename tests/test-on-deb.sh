#!/usr/bin/env bash
#################################################
#
# Valeriy Solovyov <weldpua2008@gmail.com>
# Copyright(c) 2015
###############################################

SOURCE="${BASH_SOURCE[0]}"
RDIR="$( dirname "$SOURCE" )"
ANSIBLE_VERSION=${1:-latest}
ANSIBLE_VAR=${2:-}

OS_VERSION=`cat /etc/*release | grep -oE '[0-9]+\.[0-9]+'|cut -d "." -f1 |head -n 1`
SUDO=`which sudo 2> /dev/null`
SUDO_OPTION="--sudo"
# if there wasn't sudo then ansible couldn't use it
if [ "x$SUDO" == "x" ];then
    SUDO_OPTION=""
fi

# TODO: fix  Failed to fetch http://httpredir.debian.org/debian/pool/main/p/python2.7/python2.7-dev_2.7.9-2_amd64.deb  Error reading from server. Remote end closed connection [IP: 128.31.0.66 80]
apt-get update || apt-get update
apt-get install python-pip python-dev -y
# try to fix msg: Could not import python modules: apt, apt_pkg. Please install python-apt package.
apt-get install python-apt -y -q
if [ "${OS_VERSION}" == "12" ];then
    apt-get install python-setuptools -y
    apt-get install    build-essential -y
    apt-get install ansible -y
    apt-get remove ansible --purge  -y
    apt-get install python-dev python2.7-dev python-pip -y
    apt-get install --reinstall python-pkg-resources -y
    easy_install --upgrade pip
    easy_install --upgrade ansible

fi

set -e

if [ "$ANSIBLE_VERSION" = "latest" ]; then

    pip install --upgrade ansible;
else
    pip install --upgrade ansible==$ANSIBLE_VERSION;
fi


cd $RDIR/..

printf "[defaults]\nroles_path = ../" > ansible.cfg
ansible-playbook -i tests/test-inventory tests/test.yml --syntax-check
# ANSIBLE_SHORT_VERSION=`ansible-playbook --version 2> /dev/null|cut -d " " -f2|cut -d "." -f1,2`
ansible-playbook -i tests/test-inventory tests/test.yml -vvv --connection=local ${SUDO_OPTION}

# Run the role/playbook again, checking to make sure it's idempotent.
ansible-playbook -i tests/test-inventory tests/test.yml -vvv --connection=local ${SUDO_OPTION} | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)


exit 0
