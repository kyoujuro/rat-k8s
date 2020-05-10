# minimal

![minimal](images/minimsl_config.png)

~~~
tkr@hibiki:~/rat2$ ./setup.rb -f cluster-config/minimal.yaml -s auto
Bringing machine 'bootnode' up with 'virtualbox' provider...
Bringing machine 'master1' up with 'virtualbox' provider...
Bringing machine 'node1' up with 'virtualbox' provider...
==> bootnode: Importing base box 'ubuntu/bionic64'...
==> bootnode: Matching MAC address for NAT networking...
==> bootnode: Checking if box 'ubuntu/bionic64' version '20200325.0.0' is up to date...
==> bootnode: Setting the name of the VM: rat2_bootnode_1588919770994_65014
~~~

次にbootnodeからansibleを実行する事で、Kubernetesクラスタの設定が完了する。

~~~
$ vagrant ssh bootnode
$ cd /vagrant
$ ansible-playbook -i hosts_k8s playbook/install_k8s.yml

...

PLAY RECAP ********************************************************************************************************
bootnode                   : ok=115  changed=81   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
master1                    : ok=90   changed=55   unreachable=0    failed=0    skipped=20   rescued=0    ignored=7   
node1                      : ok=66   changed=37   unreachable=0    failed=0    skipped=15   rescued=0    ignored=4   
~~~


~~~
vagrant@bootnode:/vagrant$ kubectl get node
NAME    STATUS   ROLES    AGE    VERSION
node1   Ready    worker   104s   v1.18.2
~~~


~~~
vagrant@bootnode:/vagrant$ kubectl get componentstatus
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
~~~


~~~
vagrant@bootnode:/vagrant$ kubectl cluster-info
Kubernetes master is running at https://172.16.2.4:6443
CoreDNS is running at https://172.16.2.4:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://172.16.2.4:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
~~~



~~~
vagrant@bootnode:/vagrant$ kubectl top node
NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node1   39m          3%     388Mi           43%   
~~~
