
## ROOK-CEPHのデプロイ


ROOKのコードをGitHubからクローンする。

~~~
git clone --single-branch --branch release-1.3 https://github.com/rook/rook.git 
~~~

ディレクトリを移動

~~~
cd rook/cluster/examples/kubernetes/ceph/
~~~

次のマニフェストを適用することで、ROOK-CEPHの機能を起動できる。

~~~
kubectl apply -f common.yaml
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
~~~

ポッドのリストを表示して動作を確認する。

~~~
$ kubectl get pod -n rook-ceph -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
NAME                                                 STATUS      NODE
csi-cephfsplugin-8z6d7                               Running     storage2
csi-cephfsplugin-9nrn9                               Running     storage1
csi-cephfsplugin-kkjlb                               Running     storage3
csi-cephfsplugin-provisioner-7678bcfc46-k6nph        Running     storage3
csi-cephfsplugin-provisioner-7678bcfc46-r7n2v        Running     storage2
csi-cephfsplugin-v58bp                               Running     node1
csi-rbdplugin-6m498                                  Running     storage3
csi-rbdplugin-9tgrs                                  Running     storage2
csi-rbdplugin-m868l                                  Running     node1
csi-rbdplugin-nvbxm                                  Running     storage1
csi-rbdplugin-provisioner-fbd45b7c8-m9gdm            Running     storage1
csi-rbdplugin-provisioner-fbd45b7c8-rvdm5            Running     storage3
rook-ceph-crashcollector-storage1-57d44589db-mpcch   Running     storage1
rook-ceph-crashcollector-storage2-79656cd86f-9q7vk   Running     storage2
rook-ceph-crashcollector-storage3-d86b9c568-h6r99    Running     storage3
rook-ceph-mgr-a-6ff6f577dc-dcfvq                     Running     storage2
rook-ceph-mon-a-868bd85854-hh6z6                     Running     storage3
rook-ceph-mon-b-84b6d5f757-qfzz5                     Running     storage2
rook-ceph-mon-c-7d7cc4bc64-nqsk9                     Running     storage1
rook-ceph-operator-577bdbf9b7-ctkxv                  Running     storage2
rook-ceph-osd-0-6c99c8cd64-b7dc7                     Running     storage1
rook-ceph-osd-1-56fdb558d9-qb24n                     Running     storage3
rook-ceph-osd-2-65c9965c8b-q5ggg                     Running     storage2
rook-ceph-osd-3-9c58566d5-8s9nk                      Running     storage1
rook-ceph-osd-4-649dcf58dd-xcbl4                     Running     storage3
rook-ceph-osd-5-798cbf9f85-pp6tc                     Running     storage2
rook-ceph-osd-prepare-node1-hzw88                    Succeeded   node1
rook-ceph-osd-prepare-storage1-cth2r                 Succeeded   storage1
rook-ceph-osd-prepare-storage2-fsf8n                 Succeeded   storage2
rook-ceph-osd-prepare-storage3-gvtnn                 Succeeded   storage3
rook-discover-f8qj5                                  Running     storage3
rook-discover-kbksl                                  Running     node1
rook-discover-ksqxv                                  Running     storage2
rook-discover-t66sm                                  Running     storage1
~~~

ストレージノードにLVMが設定されていることを確認

~~~
$ ssh storage1 sudo lsblk -f
NAME                                                                                                 FSTYPE      LABEL           UUID                                   MOUNTPOINT
sda                                                                                                                                                                     
└─sda1                                                                                               ext4        cloudimg-rootfs 6ff622cc-497e-49df-964f-3e554089a0ce   /
sdb                                                                                                  iso9660     cidata          2020-03-25-16-15-26-00                 
sdc                                                                                                  LVM2_member                 Bn34HR-YFk8-eqpJ-2jdf-aAPz-1MlQ-eWzJrB 
└─ceph--a08f5248--7095--48e7--be74--816f03ca425e-osd--data--867d0bf1--4ae9--4226--b91a--1a014d96b3af                                                                    
sdd                                                                                                  LVM2_member                 NK964A-UxE0-QrVJ-2WSE-wvWF-72S9-FAkWLy 
└─ceph--c1f45e9a--cd5f--4284--abb1--5febe0369777-osd--data--4bc31e9f--e9e8--4530--bfe8--9a9b288325bb    
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


