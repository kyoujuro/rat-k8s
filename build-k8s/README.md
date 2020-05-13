# ビルド環境


## Kubernetes 

K8sをソースコードからビルドするための仮想マシンを起動する

~~~
vagarnt up
~~~

仮想マシンにログインして、以下のコマンド実行して、K8sのコマンドをビルドする。
このバイナリの生成ファイルは、$GOPATH/_output/bin に集められる。


~~~
vagrant ssh
export K8SVER=v1.18.2
curl -OL https://dl.k8s.io/${K8SVER}/kubernetes-src.tar.gz
export GOPATH=`pwd`/${K8SVER}
mkdir $GOPATH
tar -C $GOPATH -xzf kubernetes-src.tar.gz
cd $GOPATH
make
~~~

vagrantの共有ディレクトリにコピーして、仮想マシンからログアウトする。

~~~
mkdir /vagrant/bin
cp _output/bin/* /vagrant/bin
exit
~~~

仮想マシンを消去する

~~~
vagrant destroy -f
~~~


## kube-keepalived-vip

### 事前にforkしたリポジトリからクローン

オリジナルのURLは https://github.com/aledbf/kube-keepalived-vip 

~~~
git clone https://github.com/takara9/kube-keepalived-vip
cd kube-keepalived-vip/
~~~

### Makefile修正箇所

~~~
all: push

# 0.0 shouldn't clobber any release builds
TAG = 0.35
HAPROXY_TAG = 0.1
# Helm uses SemVer2 versioning
CHART_VERSION = 1.0.0
#PREFIX = aledbf/kube-keepalived-vip  <<-- 自身のレポジトリ名へ修正する
PREFIX = maho/kube-keepalived-vip   
BUILD_IMAGE = build-keepalived
PKG = github.com/aledbf/kube-keepalived-vip
...

~~~

### docker レジストリサービスへログイン

~~~
vagrant@ubuntu-bionic:~/kube-keepalived-vip$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: maho
Password: 
WARNING! Your password will be stored unencrypted in /home/vagrant/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
~~~

### ビルドとコンテナリポジトリへ登録

~~~
vagrant@ubuntu-bionic:~/kube-keepalived-vip$ make
rm -f kube-keepalived-vip
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-s -w' \
-o rootfs/kube-keepalived-vip \
github.com/aledbf/kube-keepalived-vip/pkg/cmd
~~~

