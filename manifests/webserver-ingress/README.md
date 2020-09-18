## 概要

Nginx Ingress コントローラーでアプリケーションを
公開するための構成ファイル(マニフェスト）


## 説明

Ingress コントローラーを設定することで、サービスのタイプ ClusterIP で
クラスタ内部へ公開するアプリケーションを外部へ公開することができる。

このマニフェストでは、コンテナイメージ 'docker.io/maho/webapl2:0.1' を
名前空間 webserver3 の中に、デプロイメント webserver、サービス webserverとして
デプロイする。そして、イングレス webserver として Kubernetesクラスタ外へ
公開する。


## デプロイ方法

`kubectl apply -f webserver.yaml` を実行することで、前述の全てのAPIオブジェクト
をデプロイする。

~~~
$ kubectl apply -f webserver.yaml 
namespace/webserver3 created
service/webserver created
deployment.apps/webserver created
ingress.networking.k8s.io/webserver created


$ kubectl get all -n webserver3
NAME                             READY   STATUS    RESTARTS   AGE
pod/webserver-5dcfb59bff-bsvwg   1/1     Running   0          13s
pod/webserver-5dcfb59bff-k9d8k   1/1     Running   0          13s
pod/webserver-5dcfb59bff-z7wjx   1/1     Running   0          13s

NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/webserver   ClusterIP   10.32.0.30   <none>        80/TCP    13s

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webserver   3/3     3            3           13s

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/webserver-5dcfb59bff   3         3         3       13s

$ kubectl get ingress -n webserver3
NAME        CLASS    HOSTS            ADDRESS        PORTS   AGE
webserver   <none>   k8s.labs.local   172.16.23.43   80      25s
~~~


## アクセス方法

Ingressで公開するアプリケーションにアクセスするためには、
必ず DNSに登録された URLアドレスでなかればならない。

予めイングレスコントローラーが動作するノードのVIPを
外部DNSに登録しておき、そのDNSでアドレスを解決することで
ブラウザから URL k8s.labs.local によってアクセスできる。
簡便な方法では、`curl k8s.labs.local` として確認できる。

~~~
$ curl k8s.labs.local
Hostname: webserver-5dcfb59bff-k9d8k<br>
1th time access.
<br>
HTTP_CLIENT_IP = <br>
HTTP_X_FORWARDED_FOR = 10.244.104.0<br>
HTTP_X_FORWARDED = <br>
HTTP_X_CLUSTER_CLIENT_IP = <br>
HTTP_FORWARDED_FOR = <br>
HTTP_FORWARDED = <br>
REMOTE_ADDR = 10.244.135.1<br>
~~~


## クリーンナップ方法

コマンド `kubectl delete ns webserver3` によって消去できる。


