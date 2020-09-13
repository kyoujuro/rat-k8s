# Keepalived

このプレイブックでは、次の二つ種類のKeepalivedを作成する。

* インターナルKeepalived
* フロントエンドKeepalived

インターナルは、master1,master2,master3を代表する仮想IPを提供してロードバランスにより高可用性を実現する。一方、フロントエンドは、Kubernetesクラスタ外部からのトラフィックを受けるための仮想IPを提供する。ワーカーノード上のサービスをNodePortやIngressコントローラーでクラスタ外部へ公開して、高可用性と負荷分散を提供する。また、kube-apiserverのエンドポイントをKubernetesクラスタ外部へ公開する。


## インターナルのKeepalived


lb_pos に Internal とした場合は、K8sクラスタ内部のロードバランサーとして、master1,master2,master3の各々で動作するkube-apiserverの代表IPアドレス、すなわち、仮想IPアドレス(VIP)を提供する。クライアントとなるnode1〜node4、storage1〜storage3 は、このVIPをアクセスすることで、いずれかのmasterノードの停止の影響を受けなくなる。

~~~
  vars:
    lb_pos: "Internal"
~~~

以下にKeepalivedのマスター、バックアップ、仮想IPのセットするべき Ansible 変数である。

* ka_primary_internal_ip : 起動後にVIPを取得するプライパリノードのIPアドレスで、通常はmlb1のIPアドレスをセットする
* ka_backup_internal_ip : 起動後に待機につくバックアップノードのIPアドレスで、通常はmlb2のIPアドレスを設定する。
* kube_apiserver_vip : プライマとバックアップノードを代表する仮想IPアドレスである。起動時は ka_primary_internal_ip のアドレスを持つノードがkube_apiserver_vipを取得して代表となる。代表するノードが停止した場合、ka_backup_internal_ip のIPアドレスを持つノードが、kube_apiserver_vip を設定して代表として動作する。vagrant の仮想サーバー名では、mlb1 が停止すると、mlb2 が 仮想IPを設定してバックアップからプライマリーへ昇格する。


## フロントエンドのKeepalived

K8sクラスタ外部のトラフィックをK8sクラスタ内部のサービスに転送するために使用する。 Ansible変数 lb_pos = "Frontend" として与えた場合、フロントエンドのKeepalivedとして動作する。

~~~
  vars:
    lb_pos: "Frontend"
~~~

次のAnsible 変数は以下の意味を持ち、Ansibleインベントリファイル、または、Ansibleロール変数として、Ansibleプレイブックに与える。

* front_proxy_vip : 外部公開用の仮想IPアドレス
* ka_primary_frontend_ip : K8sクラスタ外部からアクセスできるIPアドレスで、プライマリノード用
* ka_backup_frontend_ip : 同様のIPアドレスで、バックアップノード用

推奨の設定としては、vagrant仮想サーバー elb1 のパブリックIPアドレスを ka_primary_frontend_ip にセットする。また ka_backup_frontend_ip にelb2のパブリックIPアドレスを設定する。


elb1とelb2は、Kubernetesクラスタのノードとして、ノードロール proxy-node として構成される。 このノードのVIPに到達したリクエストトラフィックは、NodePortやIngressコントローラーのURIに対応するサービスへ転送される。

~~~
$ kubectl get node -l role=proxy-node -L role
NAME   STATUS   ROLES   AGE     VERSION   ROLE
elb1   Ready    proxy   5h27m   v1.18.2   proxy-node
elb2   Ready    proxy   5h27m   v1.18.2   proxy-node
~~~


## 使用例-1

front_proxy_vip = 192.168.1.93 を設定して、以下のマニフェストを適用した場合、http://192.168.1.93:30083でアクセスすることができる。

~~~
apiVersion: v1
kind: Service
metadata:
  name: webserver2
spec:
  type: NodePort
  selector:
    app: webserver2
  ports:
    - port: 9080
      targetPort: 80
      nodePort: 30082
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver2
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver2
  template:
    metadata:
      labels:
        app: webserver2
    spec:
      containers:
        - image: 'maho/webapl2:0.1'
          name: webserver2
          ports:
            - containerPort: 80
~~~


## 使用例-2

下記のNodePortのKubernetesダッシュボードをブラウザからアクセスするには、フロントエンドVIPとNodePort番号を組み合わせて https://192.168.1.93:30445/ を指定すれば良い。

~~~
$ kubectl get svc kubernetes-dashboard -n kubernetes-dashboard 
NAME                   TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
kubernetes-dashboard   NodePort   10.32.0.180   <none>        443:30445/TCP   5h28m
~~~

以下のコマンドで、ログインするためのトークンを取得できる。
~~~
$ kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret |grep kubernetes-dashboard-token-* | awk '{print $1}') |awk '$1=="token:"{print $2}'
~~~

