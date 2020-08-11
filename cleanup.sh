#!/bin/bash

vagrant destroy -f

ls templates/playbook > /tmp/playbook.txt
sed s/.template// /tmp/playbook.txt > /tmp/file_list.txt

while read line
do
    find ./playbook -name $line -type f -exec rm -rf {} \;
done < /tmp/file_list.txt

rm -f ansible.log
rm -f /tmp/file_list.txt
rm -f /tmp/playbook.txt
rm -f Vagrantfile
rm -f hosts_k8s
rm -f hosts_vagrant
rm -f ubuntu-bionic-18.04-cloudimg-console.log

# template less
rm -f playbook/base_linux/templates/hosts.j2
rm -f playbook/net_bridge/tasks/static-route*
rm -f playbook/net_bridge/templates/10-bridge.conf*
rm -f playbook/haproxy/templates/haproxy_internal.cfg.j2
rm -f playbook/tasks/role_storage.yaml
rm -r playbook/tasks/role_worker.yaml

