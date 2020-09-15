# Kubernetes Dashboard UI のデプロイ用

このAnsible playbook は、ダッシュボード(Kubernetes Dashboard UI) をデプロイする。

このダッシュボードのサービスは、NodePort としてサービスを公開するので、ブラウザから、front_proxy_vip や ノードのIPアドレスを指定して アクセスできる。 アドレス例 http://node_ip_address:30445/

アクセスすることで表示されるログイン画面に入力するトークンは次のコマンドで取得できる。

~~~
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret |grep kubernetes-dashboard-token-* | awk '{print $1}') |awk '$1=="token:"{print $2}'
~~~


