# Elasticesearch, Filebeats, Kibanaのデプロイ

このAnsibleプレイブックは、Elasticseach, Filebeats, Kibana を Kubernetesクラスタへデプロイする。

Elasticsearch の サービスは、NodePort として公開するので、クラスタ外部からでもログを転送できる。
Kibanaのサービスも、NodePort として公開するので、front_proxy_vip_nomask:31200 


* ElasticSearch nodePort : 31200
* Kibana nodePort : 不明
* FileBeats の 書き込み先アドレス : front_proxy_vip_nomask:31200


