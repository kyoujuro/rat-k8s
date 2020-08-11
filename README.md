# Rat K8s


![RatK8s Logo](docs/images/rat_logo.png)

**Rat Kubernetesのロゴ**

RatK8sは、実験動物のラットにかけて、Kubernetesの学習と実験用を目的としたアップストリームKubernetesのクラスタ構成である。Kubernetesの本番システムの設計のための検証作業などを、手軽に個人のパソコン環境で実施できる様に、Vagrant + VirtalBox で仮想マシン上で稼働する。そのため、仮想マシンのホストOSは macOS、Linux, Windowsのいづれでも良い。また、今後、Terraform + パブリッククラウドでも稼働するように発展させたい。


RatK8sには以下の特徴がある。

* K8sクラスタの仮想マシンの構築は、vagrantとvirtualboxを使用して、ホストOS Windows/macOS/Linuxのいずれかの上で、仮想サーバーのマスター/ワーカーそしてロードバランサーなどを起動する。
* kubeadm コマンドを使用せず、アップストリームKubernetesのバイナリをダウンロード、または、ローカル環境でソースコードからビルドしたバイナリなどを使用して、Kubernetesクラスタを構築する。
* クラスタ・ネットワークは、オーバーレイしないブリッジかFlannelを選択できる。ブリッジではオーバーレイ・ネットワークを使わないシンプルで高スループットが期待できる。今後、Calicoなど他のCNIプラグインに対応を進める。
* kube-apiserver,kube-controller-manager,kube-scheduler,kube-proxy,kubeletなどのコンポーネントは、コンテナではなくバイナリをsystemd から起動する。
* マスターノードの数は、１〜３を選択できる。etcdはマスターノードで動作する。マスターノードが複数の場合はetcdは、それぞれをpeerとして認識して高可用性を実現する。
* マスターノードを複数で稼働させる場合は、HA構成の内部ロードバランサー mlb1とmlb2 により、高可用性と負荷分散を実装する。
* K8sクラスタの外部から内部へのリクエスト転送は、elb1/elb2 のクラスタ構成のVIPで受けて内部へ転送する。
* K8sクラスタの構成は、テンプレートとなるYAMLファイルから選択して、編集する事で、構成を変更する事ができる。

![RatK8sのシステム概要](docs/images/ratk8s_overview.png)




## 構成パターン

学習や設計のための検証実験など、目的に応じて構成を変更できるようにした。 Ansibleのプレイブックの生成プログラム setup.rbがcluster-configの定義ファイルをプレイブックの生成プログラム setup.rbが読んで必要なプレイブックの要素を生成する事で実現する。


* [最小構成](docs/config-02.md) マスターノード x1, ワーカーノード x1、ブートノード x1
* [デフォルト構成](docs/config-03.md) マスターノード x1, ワーカーノード x1、ブートノード x1
* [フル構成](docs/config-01.md) フロントLB アクティブ・スタンバイ構成,マスターノード用LB アクティブ・スタンバイ構成,マスターノード x3, アプリ用ワーカーノード x3, 永続ストレージ用ワーカーノード x3、ブートノード x1
* [フル構成+](docs/config-04.md) フロントLB アクティブ・スタンバイ構成,マスターノード用LB アクティブ・スタンバイ構成,マスターノード x3, アプリ用ワーカーノード x3, 永続ストレージ用ワーカーノード x3、ブートノード x1

※ ブートノードは、K8sクラスタを構成するノード群をAnsibleを使用して自動設定するためのノードで、AnsibleとNFSのサーバーとなっている。




## 基本的な起動方法

起動は次の３段階である。
1. setup.rb コマンドで構成に合わせたAnsible プレイブックを完成させる。
2. vagrant up で全ての仮想サーバーを起動する。
3. bootnodeからansible playbookを実行してK8sクラスタを完成させる。

ここから、具体的にコマンドラインで確認する。

(1) 次のコマンドで、クラスタ構成ファイルを読み込んで、Ansibleのコードを生成する。

~~~
git clone https://github.com/takara9/rat-k8s rat1
cd rat1
./setup.rb -f cluster-config/full.yaml 
~~~
上記のオプションで `-s auto` を追加すると`vagrant up`を省略できる。

(2) 仮想サーバー群の起動

~~~
vagrant up
~~~


(3) bootnodeからansibleを実行する事で、Kubernetesクラスタの設定が完了する。

~~~
vagrant ssh bootnode
cd /vagrant
ansible-playbook -i hosts_k8s playbook/install_k8s.yml
~~~
このプレイブックが完了すると、引き続き bootnodeで kubectlを実行できる。

~~~
kubectl get node
~~~


## クリーンナップ方法
クラスタを起動したディレクトリで、以下のコマンドを実行する事で、仮想マシンごと削除できる。

~~~
cd rat1
vagrant destroy -f
~~~


## 前提条件

仮想サーバーのホストはVagrant+VirtualBoxが動作すればLinux, MacOS, WindowsなどのホストOSを問いません。

* Vagrant (https://www.vagrantup.com/)
* VirtualBox (https://www.virtualbox.org/)
* メモリ16GB以上


### TIPS

以下に全ノードとの疎通テスト、K8sインストール、ストレージマウントのコマンドを列挙する

* ansible -i hosts_k8s all -m ping
* ansible-playbook -i hosts_k8s playbook/install_k8s.yml



## メモ ノード追加手順

* vagrant up
* export KUBECONFIG=./kubeconfig
* kubectl get no で2ノードの起動確認
* Vagrantfile の編集
* hosts_vagrant の編集
* hosts_k8sの編集
* vagrant up node2
* vagrant ssh bootnode
* sudo vi /etc/hosts ノードのエントリ追加
* cd /vagrant
* ansible -i hosts_k8s all -m ping
* ansible-playbook -i hosts_k8s playbook/add-k8s-node.yaml