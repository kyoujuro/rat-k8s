# Istio のデモアプリケーションの利用方法


## 概要

https://istio.io/latest/docs/examples/bookinfo/


`kubectl label namespace istio-demo istio-injection=enabled`の代わりに
bookinfo-namespace.yaml を利用する。



kubectl apply -k ./



http://istio.labs.local/productpage



kiali のデプロイを設定する

