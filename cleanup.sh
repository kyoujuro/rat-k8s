#!/bin/bash

echo "VMの削除"
vagrant destroy -f

ls templates/playbook > /tmp/playbook.txt
sed s/.template// /tmp/playbook.txt > /tmp/file_list.txt

echo "テンプレートから生成したファイルの削除"
while read line
do
  echo "rm -f $line"
  find ./playbook -name $line -type f -exec rm -rf {} \;
done < /tmp/file_list.txt


echo "生成ファイルの削除"
while read line
do
  echo "rm -f $line"    
  rm -f $line
done <<EOF
ansible.log
/tmp/file_list.txt
/tmp/playbook.txt
Vagrantfile
hosts_k8s
hosts_vagrant
ubuntu-bionic-18.04-cloudimg-console.log
playbook/base_linux/templates/hosts.j2
playbook/net_bridge/tasks/static-route*
playbook/net_bridge/templates/10-bridge.conf*
playbook/haproxy/templates/haproxy_internal.cfg.j2
playbook/tasks/role_storage.yaml
playbook/tasks/role_worker.yaml
playbook/tasks/add-node-label.yaml
playbook/tasks/role_worker_add.yaml
kubeconfig
EOF


echo "# dummy for keep directory on git" > playbook/vars/main.yaml
