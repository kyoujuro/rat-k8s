# Echoserver

This is a simple server that responds with the http headers it received.
Image versions >= 1.4 removes the redirect introduced in 1.3.
Image versions >= 1.3 redirect requests on :80 with `X-Forwarded-Proto: http` to :443.
Image versions > 1.0 run an nginx server, and implement the echoserver using lua in the nginx config.
Image versions <= 1.0 run a python http server instead of nginx, and don't redirect any requests.

copy from https://github.com/kubernetes-retired/contrib/tree/master/ingress/echoheaders


## ビルドとローカルでのテスト

はじめにdockerhubにログインしておく。

~~~
maho:echoserver maho$ docker login
...
~~~

コンテナをビルドしてプッシュする。

~~~
maho:echoserver maho$ make
docker build --pull -t maho/echoserver:1.4 .
Sending build context to Docker daemon  9.216kB
Step 1/4 : FROM k8s.gcr.io/nginx-slim:0.6
0.6: Pulling from nginx-slim
6d9e6e7d968b: Pull complete 
a3ed95caeb02: Pull complete 
cd23f57692f8: Pull complete 
412c0feed608: Pull complete 
dcd34d50d5ee: Pull complete 
d3c51dabc842: Pull complete 
Digest: sha256:0fe2b10615928443ea2b75934fb80bfa94fa9aab195a8e2e6e1b0d6c240dfcae
Status: Downloaded newer image for k8s.gcr.io/nginx-slim:0.6
 ---> d33636ad268a
Step 2/4 : MAINTAINER Prashanth B <beeps@google.com>
 ---> Running in 3379c470eac1
Removing intermediate container 3379c470eac1
 ---> b2e04ff9e1fd
Step 3/4 : ADD nginx.conf /etc/nginx/nginx.conf
 ---> 2bd70dc4747b
Step 4/4 : ADD README.md README.md
 ---> 2b6ea2fedff2
Successfully built 2b6ea2fedff2
Successfully tagged maho/echoserver:1.4
docker push maho/echoserver:1.4
The push refers to repository [docker.io/maho/echoserver]
0fe088cea5fb: Pushed 
9693ec16fd7f: Pushed 
5f70bf18a086: Pushed 
e2615e4925e2: Pushed 
4cc84b7b3aba: Pushed 
9f9b8efa9a34: Pushed 
e105cd217163: Pushed 
6cc9890d69b6: Pushed 
1.4: digest: sha256:d5b12dcb72c1053de0b2ad02070338979e685a12a5ff16d5a7121861d2467bfe size: 2396
~~~

これで Docker Hub https://hub.docker.com/r/maho/echoserver にプッシュされた。

ローカルにもイメージが存在する。

~~~
maho:echoserver maho$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
maho/echoserver             1.4                 2b6ea2fedff2        54 seconds ago      140MB
~~~

ローカルでの起動方法

~~~
maho:echoserver maho$ docker run -d -p 8080:8080 maho/echoserver:1.4
119fbe2039c32874473a2a30dc29f5a564f3d8f5d9f98e5329e450b5a7b60985

maho:echoserver maho$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS              PORTS                                     NAMES
119fbe2039c3        maho/echoserver:1.4   "nginx -g 'daemon of…"   3 seconds ago       Up 2 seconds        80/tcp, 443/tcp, 0.0.0.0:8080->8080/tcp   suspicious_panini
~~~

アクセステスト

~~~
maho:echoserver maho$ curl http://localhost:8080
CLIENT VALUES:
client_address=172.17.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://localhost:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=localhost:8080
user-agent=curl/7.64.1
BODY:
-no body in request-
~~~


## Kubernetesへのデプロイ

マニフェストの適用

~~~
vagrant@bootnode:/vagrant/manifests/echoserver$ kubectl apply -f echo-app.yaml 
service/echoheaders configured
deployment.apps/echoheaders configured
~~~

起動状態の確認

~~~
vagrant@bootnode:/vagrant/manifests/echoserver$ kubectl get all -l app=echoheaders
NAME                               READY   STATUS    RESTARTS   AGE
pod/echoheaders-6bbdb74cd5-d4bb2   1/1     Running   0          14s

NAME                  TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
service/echoheaders   NodePort   10.32.0.221   <none>        80:31217/TCP   14s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/echoheaders-6bbdb74cd5   1         1         1       14s
~~~

ノードポートでのアクセスのため、ノードのアドレスを確認する。

~~~
vagrant@bootnode:/vagrant/manifests/echoserver$ kubectl get node -o wide
NAME      STATUS   ROLES    AGE     VERSION   INTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master1   Ready    master   5h55m   v1.18.2   172.16.1.4    Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node1     Ready    worker   5h52m   v1.18.2   172.16.1.10   Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
node2     Ready    worker   5h52m   v1.18.2   172.16.1.11   Ubuntu 18.04.4 LTS   4.15.0-91-generic   containerd://1.2.13
~~~

## アクセステスト ノードポート経由

~~~
vagrant@bootnode:/vagrant/manifests/echoserver$ curl http://172.16.1.10:31217
CLIENT VALUES:
client_address=10.244.2.0
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://172.16.1.10:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=172.16.1.10:31217
user-agent=curl/7.58.0
BODY:
~~~

## アクセステスト kube-keepalived-vip 経由

kube-keepalived-vipの起動

~~~
vagrant@bootnode:/vagrant/manifests$ kubectl apply -f kube-keepalived-vip
~~~

コンフィグマップを設定して、サービスとVIPを対応

~~~
vagrant@bootnode:/vagrant/manifests$ cd echoserver
vagrant@bootnode:/vagrant/manifests$ kubectl apply -f vip-configmap.yaml
~~~

アクセステストの結果

~~~
vagrant@bootnode:/vagrant/manifests/echoserver$ curl http://172.16.1.200
CLIENT VALUES:
client_address=10.244.2.0
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://172.16.1.200:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=172.16.1.200
user-agent=curl/7.58.0
BODY:
-no body in request-
~~~
