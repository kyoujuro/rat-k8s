# taint と toleration のテスト

要求として、特定のポッドだけがストレージを保有するノードにスケジュールされるようにする。
ここでデータを保管するためのストレージを保有したノードをストレージノードと呼ぶことにする。ストレージノードにスケジュールされるポッドは、特定ポッドに限定する。反対に任意のポッドは、ストレージノードにスケジュールされないように制限を加えたい。


実装として、taintを設定する事で、任意のポッドがスケジュールされることを制限する。

~~~
kubectl taint node {{ ノード名 }} --overwrite=true role=storage-node:NoSchedule
~~~

ノードのラベルに役割(role)を設定して、nodeSelectorを使ってスケジュール先のノードを限定する

~~~
kubectl label node {{ item }} --overwrite=true role=storage-node
~~~


## toleration とnodeSelector で制限許可とノード選択の検証結果

ノードにtaintを設定されると、ポッドには合致するtolerationが設定されていないとスケジュールされない。

* tolerationを設定しないと、taintが設定されていないノードだけにスケジュールされる。
* nodeSelectorだけでは、目的のノードにスケジュールされるが、taintが効いているためpendingにから先へ進まない。
* tolerationだけを設定すると、role=storage-node のラベルを持たないものにもスケジューリングされる。
* tolerationとnodeSelectorの両方を設定すると、目的のノード他のポッドのデプロイを抑止して、目的のノードにデプロイされる。

## toleration と nodeAffinity で制限許可とノード選択の検証結果

nodeSelectorより詳細な設定ができるnodeAffinityを使用するケースを確認する。nodeAffinity も nodeSelector と同様に、ラベルを参照するため、ノードにラベル設定も必要である。

* nodeAffinity のみでは taint の条件を満たさないのでペンディングより先に進まない
* nodeAffinity と tolerations の両方を設定する事で、目的ノードにスケジュールされる。



## 確認のために使用したマニフェストのリスト

* deploy-no-toleration.yaml : tolerationなし
* nodeSelector-only.yaml : nodeSelectorのみ 
* deploy-toleration.yaml : tolerationのみ
* deploy-toleration-nodeSelector.yaml : toleration と nodeSelector の両方
* nodeAffinity.yaml : nodeAffinityのみ
* nodeAffinity-w-tolerate.yaml : toleration とnodeAffinityの両方






