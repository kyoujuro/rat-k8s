# full config

### 構成図

![full]("images/full_config.png")

* テンプレートファイル: cluster-config/full.yaml
* クラスタ／ポッド・ネットワーク: ブリッジ

~~~
$ git clone https://github.com/takara9/rat-k8s rat1
$ cd rat1
$ ./setup.rb -f cluster-config/full.yaml -s auto
~~~


次にbootnodeからansibleを実行する事で、Kubernetesクラスタの設定が完了する。

~~~
$ vagrant ssh bootnode
$ cd /vagrant
$ ansible-playbook -i hosts_k8s playbook/install_k8s.yml

~~~



bootnodeでノードのリストを表示したところ

~~~
$ kubectl get node -o wide
  NAME    STATUS   ROLES     AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
node1   Ready    worker    11m   v1.18.2   172.16.4.31   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node2   Ready    worker    11m   v1.18.2   172.16.4.32   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node3   Ready    worker    11m   v1.18.2   172.16.4.33   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node4   Ready    storage   11m   v1.18.2   172.16.4.61   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node5   Ready    storage   11m   v1.18.2   172.16.4.62   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node6   Ready    storage   11m   v1.18.2   172.16.4.63   <none>        Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
~~~

マスターノードのURLは、mlb1/mlb2 の VIPになっている。

~~~
$ kubectl cluster-info
Kubernetes master is running at https://172.16.4.23:6443
CoreDNS is running at https://172.16.4.23:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://172.16.4.23:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
~~~

etcdが、３台のクラスタ構成になっている点に注目してほしい。

~~~
vagrant@bootnode:/vagrant$ kubectl get componentstatus
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}   
etcd-1               Healthy   {"health":"true"}   
~~~

metrics-serverが正しく動いていれば、`kubectl top`が動作する。


~~~
vagrant@bootnode:/vagrant$ kubectl top node
NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node1   27m          2%     569Mi           64%       
node2   30m          3%     533Mi           60%       
node3   27m          2%     527Mi           59%       
node4   41m          2%     658Mi           17%       
node5   44m          2%     637Mi           16%       
node6   42m          2%     632Mi           16%      
~~~