# 内部DNS CoreDNS

このAnsible プレイブックは、Kubernetesクラスタ内部のDNSサーバーを設定する。

KubernetesクラスタのIPアドレスは、setup.rb コマンドで ConfigMapの構成ファイルを作成して自動登録される。また、Kubernetesのオブジェクト生成時は自動登録されるので、利用者が何かを実施する必要はない。


