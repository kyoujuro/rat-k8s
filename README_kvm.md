# How to kvm


~~~
$ bundler install
$ setup.rb -f cluster-config/standard-mini-kvm.yaml
$ cd virt
$ sudo -s
# create_nodes.sh
# ssh -i id_rsa ubuntu@172.16.5.10
# ansible-playbook -i hosts_kvm playbook/setup_linux.yaml
# ansible-playbook -i hosts_kvm playbook/install_k8s.yaml
~~~


