#!/bin/bash

echo "VMの削除"
vagrant destroy -f

if [ -f hosts_k8s ]; then
# Subnetの削除
SUBNET=`grep internal_subnet hosts_k8s | sed "s/internal_subnet=//"`
VBOX_IF=`ip route |grep $SUBNET |awk '{ print $3 }'`
VBOX_NET_STATUS=`ip route |grep $SUBNET |awk '{ print $10 }'`

if [ $VBOX_NET_STATUS == "linkdown" ]; then
    echo "VBOXネットワークの削除"    
    VBoxManage hostonlyif remove $VBOX_IF
fi
fi

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
hosts_local
virt/01-netcfg.yaml
virt/id_rsa
virt/id_rsa.pub
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
hosts_hv
hosts_kvm
EOF

git checkout playbook/cert_setup/vars/main.yaml

echo "# dummy for keep directory on git" > playbook/vars/main.yaml
