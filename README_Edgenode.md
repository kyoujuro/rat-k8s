## メモ エッジノードの追加

* sudo vi /etc/hosts ノードのエントリ追加
* playbook/vars/main.yaml にノード追加
* hosts_k8s にノード追加
* エッジノードの証明書を作成 add-vk-node.yaml
  ansible-playbook -i hosts_k8s playbook/add-vk-node.yaml
* kubeconfigのコピー


#!/bin/bash
# VM Host IP
export VKUBELET_POD_IP=192.168.33.10
export APISERVER_CERT_LOCATION="/etc/virtual-kubelet/client.crt"
export APISERVER_KEY_LOCATION="/etc/virtual-kubelet/client.key"
export KUBELET_PORT="10250"
export KUBERNETES_SERVICE_PORT="8443"

# minikube Host IP
export KUBERNETES_SERVICE_HOST=192.168.99.105
cd bin
./virtual-kubelet --provider cri --kubeconfig ../admin.conf

