# Kubernetes ビルド環境

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

