# イングレスコントローラのデプロイ

イングレスコントローラは、Kubernetesクラスタ外部のクライアントからのリクエストトラフィックを
内部のサービスへ導くためのコントローラーである。

イングレスコントローラーには、複数の実装がある。

* Nginx Ingress Controller
* HAPROXY Ingress Controller
* Envoy

次は比較
https://medium.com/swlh/kubernetes-ingress-controller-overview-81abbaca19ec


このAnsible プレイブックでは、Nginx Ingress コントローラーについて扱う


elb vip 80 ポートにIngressコントローラーのHTTPポート 31080を対応づけ、elb vip 443 ポートにIngressコントローラーのHTTPSポート31443を繋いでいる。

coredns に Ingress のドメイン名  ingress.labs.local を設定する。


