# メモ

IPアドレスについてメモしておく。

## developer.yaml
  ノード構成
    master 1
    node 1/2
    bootnode 

  IPアドレス
    クラスタネット 172.16.1.0/24
    外部IP node1:192.168.1.40,node2:192.168.1.41


## full-calico-debug.yaml
  ノード構成
    master 1/2/3
    node 1/2/3/4
    mlb 1/2
    elb 1/2
    bootnode
    
  IPアドレス
    クラスタネット 172.16.5.0/24
    外部IP
    elb vip 192.168.1.200
    elb1 192.168.1.198
    elb2 192.168.1.199
    

## full-calico.yaml
  ノード構成
    master 1/2/3
    node 1/2/3/4
    mlb 1/2
    elb 1/2
    bootnode
    
  IPアドレス
    クラスタネット 172.16.10.0/24
    外部IP
    elb vip 192.168.1.210
    elb1 192.168.1.208
    elb2 192.168.1.209

## 以下未整理

ここに挙げたものは、elb 1/2 と proxy 1/2 の設定が混乱している状態なので使わない方が良い

* full-proxy-rook.yaml
* full-rook.yaml
* full.yaml


## minimal.yaml
  ノード構成 ３台構成
    master 1
    node 1
    bootnode 

  IPアドレス
    クラスタネット 172.16.2.0/24
    外部IP
      node1:192.168.1.40

## rook-mini.yaml
 ROOKの起動専用
  ノード構成
    master 1
    node 1/2
    storage 1/2/3
    bootnode 
  IPアドレス
    クラスタネット 172.16.4.0/24
    外部IP なし
 
## standard-bridge.yaml
 CNIプラグインに Bridge を利用
 ポッドネットワークはスタティックルーティングで設定

 ノード構成
   master 1
   node 1/2
   bootnode

 IPアドレス
     クラスタネット 172.16.7.0/24
     外部IP master1 192.168.1.97

## standard-calico.yaml
 CNIプラグインに Calicoを利用
 ポッドネットワークはBGPルーティングで自動化

 ノード構成
   master 1
   node 1/2
   bootnode

 IPアドレス
     クラスタネット 172.16.5.0/24
     外部IP master1 192.168.1.95


## standard-flannel.yaml
 CNIプラグインに flannelを利用
 ポッドネットワークはVX-LANで相互接続

 ノード構成
   master 1
   node 1/2
   bootnode

 IPアドレス
     クラスタネット 172.16.6.0/24
     外部IP master1 192.168.1.96


## storage-in-mz.yaml
 Cephのマルチゾーン構成を組んだ例
    node_label:
    - app: rook-ceph-mds
    - topology.kubernetes.io/zone: tok02      

    node_label:
    - app: rook-ceph-mds
    - topology.kubernetes.io/zone: tok04

    node_label:
    - app: rook-ceph-mds
    - topology.kubernetes.io/zone: tok05

## 未整理
これらは廃止予定
 * standard-mini.yamlは、standard-flanne.yamlと同じ
 * standard.yaml full と同じ


