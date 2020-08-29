ラズパイなどARM CPUを搭載したエッジノードでは、
x86-64用にビルドされたコンテナイメージをデプロイすることはできない。

ARM64 に x86-64 のイメージがデプロイされない様に
ラズパイノードに taint を設定する。


taintの設定

$ kubectl taint nodes raspi07 cpu=arm64:NoSchedule
node/raspi07 tainted



taintの確認

$ kubectl get node raspi07 -o jsonpath='{.spec.taints}'
[map[effect:NoSchedule key:cpu value:arm64]]



taintの削除

$ kubectl taint nodes raspi07 cpu:NoSchedule-


arm プロセッサのノードにデプロイ

~~~
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  tolerations:
  - key: "cpu"
    operator: "Equal"
    value: "arm64"
    effect: "NoSchedule"
    