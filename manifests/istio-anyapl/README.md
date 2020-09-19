# Istio Gateway を使って公開するアプリケーションの例

このサンプルでは、Nginx と Apache httpd の二つのウェブサーバーを
Istio を使ってKubernetesクラスタの外部へ公開します。


## ファイルの説明

* webapl-namespace.yaml     : このアプリ用の名前空間を作成、Isitoインジェクションの指定
* webapl-deployment-v1.yaml : アプリとしてNginxを起動
* webapl-deployment-v2.yaml : アプリとしてApache httpdを起動
* webapl-service.yaml       : ラベル app: webapls へリクエストを振るサービス
* webapl-destination-rule.yaml : webapls の転送先を設定
* webapl-virtual-service.yaml  : Ingressゲートウェイとポッドを繋ぐ仮想サービス
* webapl-virtual-service-weighted.yaml : 上記にウェイトを設定した版
* webapl-gateway.yaml : 外部にサービスを公開するIngressゲートウェイ


## デプロイ方法

kubectl apply -k ./


## ウェイト設定

kubectl apply -f webapl-virtual-service-weighted.yaml


## クリーンナップ

kubectl delete ns istio-anyapl


