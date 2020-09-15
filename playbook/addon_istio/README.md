# Istio サービスメッシュのデプロイ

Istioをデプロイする Ansible プレイブックである。

Istio のプロファイルは default を用いる。この環境では、クラウドのような LoadBalancer が無いため、NodePort として IngressGateway を公開する。

80番ポートを開くために、
