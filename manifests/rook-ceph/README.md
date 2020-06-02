
## ROOK-CEPHのデプロイ


次の３つのマニフェストを適用することで、ROOK-CEPHの機能を起動できる。

~~~
kubectl apply -f common.yaml
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
kubectl apply -f dashboard-nodeport.yaml
kubectl apply -f storageclass-rbd.yaml
~~~

ポッドが動作しているノードが表示されるように、コマンドのオプションを組み立てた例

~~~
$ kubectl get pod -n rook-ceph -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
NAME                                                 STATUS      NODE
csi-cephfsplugin-gjx6b                               Running     node1
csi-cephfsplugin-gxvq9                               Running     node2
csi-cephfsplugin-kc4vh                               Running     node4
csi-cephfsplugin-provisioner-599f5994c6-ctxrq        Running     node4
csi-cephfsplugin-provisioner-599f5994c6-zv6x4        Running     node4
csi-cephfsplugin-xjdft                               Running     node3
csi-rbdplugin-cmszs                                  Running     node2
csi-rbdplugin-hqjzx                                  Running     node4
csi-rbdplugin-hr5b2                                  Running     node1
csi-rbdplugin-provisioner-54c47fdcc7-xkx4l           Running     node2
csi-rbdplugin-provisioner-54c47fdcc7-z28z9           Running     node1
csi-rbdplugin-pxb22                                  Running     node3
rook-ceph-crashcollector-storage1-565d7f4b6d-qtfzv   Running     storage1
rook-ceph-crashcollector-storage2-796947bdf7-f8nkc   Running     storage2
rook-ceph-crashcollector-storage3-c79dbfb94-6dq8n    Running     storage3
rook-ceph-mgr-a-5c9b6ccc96-f2kq4                     Running     storage2
rook-ceph-mon-a-79c4f8bf75-95s6n                     Running     storage2
rook-ceph-mon-b-c97f894f-ld6tl                       Running     storage1
rook-ceph-mon-c-84554f6598-mpwkc                     Running     storage3
rook-ceph-operator-658dfb6cc4-rhgkk                  Running     node4
rook-ceph-osd-0-84d7596478-hw25d                     Running     storage1
rook-ceph-osd-1-7f8d7cfbd6-q9fcs                     Running     storage3
rook-ceph-osd-2-66688b68b7-92qm2                     Running     storage2
rook-ceph-osd-prepare-storage1-ftf7z                 Succeeded   storage1
rook-ceph-osd-prepare-storage2-z222g                 Succeeded   storage2
rook-ceph-osd-prepare-storage3-6tss8                 Succeeded   storage3
rook-discover-9lqgh                                  Running     node3
rook-discover-bqjd5                                  Running     node4
rook-discover-glb6j                                  Running     node2
rook-discover-hknjn                                  Running     node1
~~~




## ダッシュボードへのアクセス

次のマニフェストを提供してNodePortを開く。これでPublic IPを持ったノード経由で、Cephダッシュボードへのアクセスが可能になる。

~~~
$ kubectl apply -f dashboard-external-https.yaml 
~~~


Cephダッシュボードの初期パスワードの取得は次のコマンド

~~~
$ kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
5yUC5QKKqA
~~~

フル構成の場合、プロキシノードのノードポートからアクセスが可能になる。

https://192.168.1.98:30443/ https://192.168.1.99:30443/


## rbd

~~~
vagrant@bootnode:/vagrant/manifests/rook/cluster/examples/kubernetes/ceph/csi/rbd$ ls
pod.yaml  pvc-restore.yaml  pvc.yaml  snapshot.yaml  snapshotclass.yaml  storageclass-ec.yaml  storageclass-test.yaml  storageclass.yaml
~~~


~~~
$ kubectl apply -f storageclass.yaml 
$ kubectl get sc
NAME              PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
rook-ceph-block   rook-ceph.rbd.csi.ceph.com      Delete          Immediate           true                   5s
~~~

~~~
$ kubectl apply -f pvc.yaml 
~~~

~~~
$ kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
rbd-pvc      Bound    pvc-a3c040be-d74e-4061-833b-22c653ab6736   1Gi        RWO            rook-ceph-block   6s
~~~


~~~
$ kubectl apply -f pod.yaml 
~~~

~~~
$ kubectl get pod
NAME              READY   STATUS    RESTARTS   AGE
csirbd-demo-pod   1/1     Running   0          71s
~~~

~~~
$ kubectl exec -it csirbd-demo-pod -- bash
root@csirbd-demo-pod:/# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay         9.7G  3.6G  6.1G  37% /
tmpfs            64M     0   64M   0% /dev
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
shm              64M     0   64M   0% /dev/shm
/dev/sda1       9.7G  3.6G  6.1G  37% /etc/hosts
/dev/rbd0       976M  2.6M  958M   1% /var/lib/www/html
tmpfs           3.9G   12K  3.9G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs           3.9G     0  3.9G   0% /proc/acpi
tmpfs           3.9G     0  3.9G   0% /proc/scsi
tmpfs           3.9G     0  3.9G   0% /sys/firmware
~~~




## Cephファイルシステムの利用

~~~
kubectl apply -f filesystem.html
~~~

~~~
cd csi/cephfs
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml
~~~


~~~
vagrant@bootnode:/vagrant/manifests/rook/cluster/examples/kubernetes/ceph/csi/cephfs$ kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cephfs-pvc   Bound    pvc-73391e91-aed5-4571-8459-b9e190bfeaa6   1Gi        RWO            rook-cephfs    6s
~~~


~~~
vagrant@bootnode:/vagrant/manifests/rook/cluster/examples/kubernetes/ceph/csi/cephfs$ kubectl describe pvc cephfs-pvc
Name:          cephfs-pvc
Namespace:     default
StorageClass:  rook-cephfs
Status:        Bound
Volume:        pvc-73391e91-aed5-4571-8459-b9e190bfeaa6
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: rook-ceph.cephfs.csi.ceph.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Mounted By:    <none>
Events:
  Type    Reason                 Age   From                                                                                                              Message
  ----    ------                 ----  ----                                                                                                              -------
  Normal  ExternalProvisioning   2m1s  persistentvolume-controller                                                                                       waiting for a volume to be created, either by external provisioner "rook-ceph.cephfs.csi.ceph.com" or manually created by system administrator
  Normal  Provisioning           2m1s  rook-ceph.cephfs.csi.ceph.com_csi-cephfsplugin-provisioner-7459667b67-chw7f_02030e6d-28a0-40d5-8ff8-2f04e6d2d5bd  External provisioner is provisioning volume for claim "default/cephfs-pvc"
  Normal  ProvisioningSucceeded  119s  rook-ceph.cephfs.csi.ceph.com_csi-cephfsplugin-provisioner-7459667b67-chw7f_02030e6d-28a0-40d5-8ff8-2f04e6d2d5bd  Successfully provisioned volume pvc-73391e91-aed5-4571-8459-b9e190bfeaa6
~~~








## ツールボックスによる動作確認

CEPHツールを収めたコンテナを起動する。

~~~
$ kubectl create -f toolbox.yaml
~~~

起動を確認する。

~~~
$ kubectl -n rook-ceph get pod -l "app=rook-ceph-tools"
~~~

対話モードでシェルを起動する

~~~
$ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash
~~~



## Cephの状態をコマンドラインで取得


~~~
[root@rook-ceph-tools-55d5c49f79-c7ldf /]# ceph status
  cluster:
    id:     7e126f9b-dfbf-46cd-b168-4200e55bd871
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 13m)
    mgr: a(active, since 13m)
    osd: 3 osds: 3 up (since 13m), 3 in (since 13m)
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   22 GiB used, 96 GiB / 117 GiB avail
    pgs:     
~~~


https://docs.ceph.com/docs/master/rados/operations/monitoring/

~~~
[root@rook-ceph-tools-55d5c49f79-c7ldf /]# ceph osd status
+----+----------+-------+-------+--------+---------+--------+---------+-----------+
| id |   host   |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
+----+----------+-------+-------+--------+---------+--------+---------+-----------+
| 0  | storage1 | 7351M | 31.9G |    0   |     0   |    0   |     0   | exists,up |
| 1  | storage3 | 7351M | 31.9G |    0   |     0   |    0   |     0   | exists,up |
| 2  | storage2 | 7351M | 31.9G |    0   |     0   |    0   |     0   | exists,up |
+----+----------+-------+-------+--------+---------+--------+---------+-----------+
~~~



~~~
[root@rook-ceph-tools-55d5c49f79-c7ldf /]# ceph df
RAW STORAGE:
    CLASS     SIZE        AVAIL      USED       RAW USED     %RAW USED 
    hdd       117 GiB     96 GiB     22 GiB       22 GiB         18.35 
    TOTAL     117 GiB     96 GiB     22 GiB       22 GiB         18.35 
 
POOLS:
    POOL     ID     STORED     OBJECTS     USED     %USED     MAX AVAIL 
~~~


~~~
[root@rook-ceph-tools-55d5c49f79-c7ldf /]# rados df
POOL_NAME USED OBJECTS CLONES COPIES MISSING_ON_PRIMARY UNFOUND DEGRADED RD_OPS RD WR_OPS WR USED COMPR UNDER COMPR 

total_objects    0
total_used       22 GiB
total_avail      96 GiB
total_space      117 GiB
~~~



## Cephファイルシステム













## WordPress の起動

ストレージクラスの設定

~~~
$ kubectl apply -f storageclass-rbd.yaml 
cephblockpool.ceph.rook.io/replicapool created
storageclass.storage.k8s.io/rook-ceph-block created

$ kubectl get sc
NAME              PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
rook-ceph-block   rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   5s
~~~



~~~
$ ls wp
mysql.yaml  wordpress.yaml

$ kubectl apply -f wp
~~~


~~~
$ kubectl get pod
NAME                               READY   STATUS    RESTARTS   AGE
wordpress-7bfc545758-bjcv9         1/1     Running   0          3m29s
wordpress-mysql-764fc64f97-smwrx   1/1     Running   0          3m30s

$ kubectl get pvc
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
mysql-pv-claim   Bound    pvc-0c15136b-606d-4cf9-9424-0db630a715eb   20Gi       RWO            rook-ceph-block   3m37s
wp-pv-claim      Bound    pvc-ebf03eda-72dd-4434-8afc-d7bf4e77658b   20Gi       RWO            rook-ceph-block   3m36s

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
pvc-0c15136b-606d-4cf9-9424-0db630a715eb   20Gi       RWO            Delete           Bound    default/mysql-pv-claim
pvc-ebf03eda-72dd-4434-8afc-d7bf4e77658b   20Gi       RWO            Delete           Bound    default/wp-pv-claim
~~~



$ kubectl create -f object.yaml
$ kubectl -n rook-ceph get pod -l app=rook-ceph-rgw
NAME                                        READY   STATUS    RESTARTS   AGE
rook-ceph-rgw-my-store-a-5f9f7558f9-hck86   1/1     Running   0          103s



$ kubectl apply -f storageclass-bucket-delete.yaml



$ kubectl apply -f object-bucket-claim-delete.yaml
objectbucketclaim.objectbucket.io/ceph-delete-bucket created




$ sudo apt install s3cmd


