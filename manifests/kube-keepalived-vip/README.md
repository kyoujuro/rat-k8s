# kube-keepalived-vip

このマニフェストは、k8sクラスタの外側からのリクエストを内部のサービスに導くものである。

Kubernetesではシステム構成の規模に応じて柔軟な構成を組むことができる。


## プロキシ専用ノードに配置

cluster-config/full-proxy-rook.yaml を使って作成したAnsible playbookで構築したクラスタのproxy1とproxy2ノードにデプロイするために作ったマニフェストである。このクラスタのラベル 'role: proxy-node' を持ったノードにデプロイする。そして、このAPIオブジェクトkube-keepalived-vip は、名前空間 kube-system に配置することで、他のアプリケーションから分離される。

* proxy-sa.yaml
* proxy-rbac.yaml
* proxy-configmap.yaml
* proxy-daeminset.yaml


VIPの設定は、proxy-configmap.yamlを編集して実施する。以下の data.192.168.1.240 は 仮想IPアドレスで、代表ノードが自動的に選出されアサインされる。そして、このIPアドレスは、名前空間名/サービス名に対応づけられる。 以下の例では、名前空間 default の サービス webserver に対応する。このVIPにIngress コントローラーを対応させることができる。

~~~
apiVersion: v1
kind: ConfigMap
metadata:
  name: proxy-configmap
  namespace: kube-system
data:
  192.168.1.240: default/webserver
  192.168.1.241: haproxy-controller/haproxy-ingress    
~~~

## 使用方法

このマニフェストのwebserverを例としてアプリケーションを外部に公開する順番は、次のようになる。

1. webserver アプリケーションをデプロイする。
2. kube-keepalived-vip をデプロイする。

コマンドの実行順番としては、次のようになる。

~~~
cd manifests/webserver
kubectl apply -f webserver
cd ../kube-keepalived-vip
kubectl apply -f proxy-sa.yaml
kubectl apply -f proxy-rbac.yaml
kubectl apply -f proxy-configmap.yaml
kubectl apply -f proxy-daemonset.yaml
~~~

上記のマニフェストを適用することで、default/webserver のサービスを仮想IPアドレス 192.168.1.240 に公開することができる。
この方法の場合、DNS名がない IPアドレスだけでもアクセスが可能である。


## ワーカーノードに配置

vip-configmap.yaml
vip-daemonset.yaml
vip-rbac.yml



## 参考資料

* https://github.com/aledbf/kube-keepalived-vip
* https://github.com/takara9/kube-keepalived-vip
