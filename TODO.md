## TODOなど、やってみたいこと。

技術的な理解を深め、スキルを磨くことを目指して、実施したいこと

* 外部むけロードバランサーのVIPと外部DNSの連携
* crictl の環境設定
* etcdctl の動作確認
* Calicoの適用
* コンフィグスクリプトの開発、ノード数、資源量変更など
* Terraformで作成したホストでのk8sのデプロイ


## 必要なパーツのビルド

build-k8sの仮想マシンを使ってK8sの本体やアドオンをビルドする

* Kubernetes本体: 済み
* kube-keepalived-vip: 済み
* coredns: 済み
* haproxy-ingress: 
* nginx-ingress: 