

~~~
kubectl apply -f common.yaml
kubectl apply -f operator.yaml
~~~

~~~
kubectl get pod -n rook-ceph
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-operator-658dfb6cc4-rhgkk   1/1     Running   0          6m23s
rook-discover-9lqgh                   1/1     Running   0          5m23s
rook-discover-bqjd5                   1/1     Running   0          5m23s
rook-discover-glb6j                   1/1     Running   0          5m23s
rook-discover-hknjn                   1/1     Running   0          5m23s
~~~

上記の状態になったら、以下のマニフェストを適用する

~~~
$ kubectl apply -f cluster.yaml 
~~~

最終的に以下の状態になれば起動完了

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

## ツールボックスによる動作確認

~~~
$ kubectl create -f toolbox.yaml
~~~


~~~
$ kubectl -n rook-ceph get pod -l "app=rook-ceph-tools"
NAME                               READY   STATUS    RESTARTS   AGE
rook-ceph-tools-55d5c49f79-c7ldf   1/1     Running   0          50s
~~~


~~~
$ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash
[root@rook-ceph-tools-55d5c49f79-c7ldf /]#
~~~


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


## ダッシュボード


~~~
$ kubectl -n rook-ceph get service rook-ceph-mgr-dashboard 
NAME                      TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
rook-ceph-mgr-dashboard   ClusterIP   10.32.0.87   <none>        8443/TCP   33m
~~~

サービスタイプをノードポートへ変更

~~~
$ kubectl -n rook-ceph edit service rook-ceph-mgr-dashboard
~~~

~~~
 59 spec:
 60   clusterIP: 10.32.0.87
 61   ports:
 62   - name: https-dashboard
 63     port: 8443
 64     protocol: TCP
 65     targetPort: 8443
 66     nodePort: 31443
 67   selector:
 68     app: rook-ceph-mgr
 69     rook_cluster: rook-ceph
 70   sessionAffinity: None
 71   type: NodePort
 72 status:
~~~

~~~
$ kubectl -n rook-ceph get service rook-ceph-mgr-dashboard 
NAME                      TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
rook-ceph-mgr-dashboard   NodePort   10.32.0.87   <none>        8443:31443/TCP   37m
~~~

~~~
$ kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
5yUC5QKKqA
~~~

https://192.168.1.98:31443/ https://192.168.1.99:31443/



## ストレージクラス

~~~
$ kubectl apply -f storageclass-rbd.yaml 
cephblockpool.ceph.rook.io/replicapool created
storageclass.storage.k8s.io/rook-ceph-block created

$ kubectl get sc
NAME              PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
rook-ceph-block   rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   5s
~~~




## WordPress の起動


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


