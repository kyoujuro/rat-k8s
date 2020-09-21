# Istio サービスメッシュのデプロイ

Istioをデプロイする Ansible プレイブックである。

Istio のプロファイルは default を用いる。この環境では、クラウドのような LoadBalancer が無いため、NodePort として IngressGateway を公開する。


* 80番ポートを開くために、elb1/2 のhaproxy を設定
* istio-ingressgateway は NodePortで公開 elb1/elb2 の HA-Proxyから転送
* elb1/elb2 の vip、HA-PROXY ポート番号 80 で公開
* vipは、isito.labs.local に設定
* istioctl コマンドは、bootnode の/usr/local/binへ配置

