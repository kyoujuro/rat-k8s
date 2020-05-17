# taint と toleration のテスト

下記のtaintが設定されている場合の振る舞い

~~~
Taints: role=storage-node:NoSchedule
~~~

## 検証結果

* tolerationを設定しないと、taintが設定されていないノードだけにスケジュールされる。
* nodeSelectorだけでは、目的のノードにスケジュールされるが、taintが効いているためpendingにから先へ進まない。
* tolerationだけを設定すると、role=storage-node のラベルを持たないものにもスケジューリングされる。
* tolerationとnodeSelectorの両方を設定すると、目的のノード他のポッドのデプロイを抑止して、目的のノードにデプロイされる。


## マニフェストのリスト

* deploy-no-toleration.yaml : tolerationなし
* nodeSelector-only.yaml : nodeSelectorのみ 
* deploy-toleration.yaml : tolerationのみ
* deploy-toleration-nodeSelector.yaml : toleration と nodeSelector の両方


## テスト結果

~~~
$ kubectl get pod  -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
no-toleration-587f45d5bb-2j42r         1/1     Running   8          85m   10.244.4.6     node4    <none>           <none>
no-toleration-587f45d5bb-45l79         1/1     Running   8          85m   10.244.2.6     node2    <none>           <none>
no-toleration-587f45d5bb-8cxbh         1/1     Running   8          85m   10.244.3.5     node3    <none>           <none>
no-toleration-587f45d5bb-dpc89         1/1     Running   8          85m   10.244.3.4     node3    <none>           <none>
no-toleration-587f45d5bb-hhg9s         1/1     Running   8          85m   10.244.2.4     node2    <none>           <none>
no-toleration-587f45d5bb-qmsjm         1/1     Running   8          85m   10.244.2.5     node2    <none>           <none>
no-toleration-587f45d5bb-qwlrt         1/1     Running   8          85m   10.244.4.4     node4    <none>           <none>
no-toleration-587f45d5bb-s8bcf         1/1     Running   8          85m   10.244.4.5     node4    <none>           <none>
no-toleration-587f45d5bb-vt2lt         1/1     Running   8          85m   10.244.1.4     node1    <none>           <none>
no-toleration-587f45d5bb-z9fjg         1/1     Running   8          85m   10.244.1.5     node1    <none>           <none>
node-selector-dc6878b54-6d97p          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-cwdsv          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-hlvb6          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-kzc25          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-njrsr          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-r2msz          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-r8mhh          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-v7kks          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-wqxmb          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
node-selector-dc6878b54-xn5b4          0/1     Pending   0          14s   <none>         <none>   <none>           <none>
toler-node-selector-55dd9b9944-2sg94   1/1     Running   6          69m   10.244.22.9    node6    <none>           <none>
toler-node-selector-55dd9b9944-8h2ql   1/1     Running   6          69m   10.244.21.10   node5    <none>           <none>
toler-node-selector-55dd9b9944-8psp8   1/1     Running   6          69m   10.244.21.9    node5    <none>           <none>
toler-node-selector-55dd9b9944-94bqk   1/1     Running   6          69m   10.244.22.10   node6    <none>           <none>
toler-node-selector-55dd9b9944-hjkwb   1/1     Running   6          69m   10.244.23.8    node7    <none>           <none>
toler-node-selector-55dd9b9944-j5vwr   1/1     Running   6          69m   10.244.23.7    node7    <none>           <none>
toler-node-selector-55dd9b9944-ks7gk   1/1     Running   6          69m   10.244.23.9    node7    <none>           <none>
toler-node-selector-55dd9b9944-sk8jp   1/1     Running   6          69m   10.244.21.7    node5    <none>           <none>
toler-node-selector-55dd9b9944-szhzg   1/1     Running   6          69m   10.244.22.11   node6    <none>           <none>
toler-node-selector-55dd9b9944-tzrfq   1/1     Running   6          69m   10.244.21.8    node5    <none>           <none>
toleration-deploy-849cbfc8c5-65wl6     1/1     Running   9          92m   10.244.2.3     node2    <none>           <none>
toleration-deploy-849cbfc8c5-bccjf     1/1     Running   9          92m   10.244.22.4    node6    <none>           <none>
toleration-deploy-849cbfc8c5-dddvm     1/1     Running   9          92m   10.244.4.3     node4    <none>           <none>
toleration-deploy-849cbfc8c5-dwvwf     1/1     Running   9          92m   10.244.21.3    node5    <none>           <none>
toleration-deploy-849cbfc8c5-jzd7c     1/1     Running   9          92m   10.244.22.3    node6    <none>           <none>
toleration-deploy-849cbfc8c5-m547j     1/1     Running   9          92m   10.244.3.3     node3    <none>           <none>
toleration-deploy-849cbfc8c5-t28s4     1/1     Running   9          92m   10.244.21.2    node5    <none>           <none>
toleration-deploy-849cbfc8c5-tjl28     1/1     Running   9          92m   10.244.3.2     node3    <none>           <none>
toleration-deploy-849cbfc8c5-tx95j     1/1     Running   9          92m   10.244.1.3     node1    <none>           <none>
toleration-deploy-849cbfc8c5-tz7ls     1/1     Running   9          92m   10.244.23.3    node7    <none>           <none>
~~~

