#!/usr/bin/ruby
# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
#
# エラー発生時の対策メモ
#
# 1 このプログラムを実行する前に bundler を実行して必要なモジュールをインストール
#
# 2 次のメッセージで困った時はinvalid byte sequence in US-ASCII (ArgumentError)
#   export LANG=C.UTF-8 を実行する


require 'mb_string'
require 'yaml'
require 'json'
require 'net/ping'
require './libruby/read_yaml.rb'
require './libruby/util_defs.rb'
require './libruby/scan_available_ip.rb'
require './libruby/cni_bridge.rb'
require './libruby/conf_etcd.rb'
require './libruby/conf_haproxy.rb'
require './libruby/identify_hostos.rb'
require './libruby/output_ansible_inventory.rb'


$insert_msg  = "### THIS FILE IS GENERATED BY setup.rb ###\n"
$domain = nil
$sub_domain = nil
$exist_proxy_node = nil
$exist_storage_node = nil
$mode = nil
$single_node = nil
$search_ip = false
$ping_list = []
$hypervisor_os = nil

$cnt = {
  "master"  => 0,
  "node"    => 0,
  "proxy"   => 0,
  "storage" => 0,
  "elb"     => 0,
  "mlb"     => 0,
  "mon"     => 0
}

$file_list = []



##
## Linuxの/etc/hosts設定
## playbook/base_linux/templates/hosts.j2
##
def create_hosts_file()
  ofn = "playbook/base_linux/templates/hosts.j2"
  $file_list.push(ofn)
  File.open(ofn, "w") do |w|
    w.write $insert_msg
    w.write sprintf("%-20s %-16s %-20s\n","127.0.0.1", "localhost", "localhost.localdomain")
    $vm_config_array.each do |val|
      x = eval(val)
      if x['private_ip'].nil? == false
        w.write sprintf("%-20s %-16s %-20s\n",x['private_ip'], x['name'], x['name'] + "." + $domain)
      elsif x['public_ip'].nil? == false
        w.write sprintf("%-20s %-16s %-20s\n",x['public_ip'], x['name'], x['name'] + "." + $domain)
      end
    end
  end
end


##
## Ansibleの変数設定
##   playbook/vars/main.yaml
##
def vars_nodelist()

  tfn = "templates/playbook/var-main.yaml.template"
  ofn = "playbook/vars/main.yaml"
  $file_list.push(ofn)
  File.open(tfn, "r") do |f|
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        
        if line =~ /^__AUTO_CONFIG__*/
          $vm_config_array.each do |val|
            x = eval(val)
            if x.has_key?('public_ip') and x.has_key?('private_ip')
              w.write sprintf("  - { name: %-10s, pub_ip: %-15s, pri_ip: %-15s }\n",
                              "'" + x['name'] + "'",
                              "'" + x['public_ip'] + "'",
                              "'" + x['private_ip'] + "'")
            elsif x.has_key?('public_ip')
              # 本当は pub_ip だが、便宜上 pri_ip として書き出す
              w.write sprintf("  - { name: %-10s, pri_ip: %-15s }\n",
                              "'" + x['name'] + "'",
                              "'" + x['public_ip'] + "'")
            else
              w.write sprintf("  - { name: %-10s, pri_ip: %-15s }\n",
                              "'" + x['name'] + "'",
                              "'" + x['private_ip'] + "'")
            end
          end
        else
          w.write line        
        end
      }
    end
  end
end

#
# CoreDNSのエントリーをコンフィグを元に追加
#                       coredns-configmap.yaml
#
def coredns_config()

  dns_entry = ""
  $vm_config_array.each do |val|
    x = eval(val)
    dns_entry = dns_entry + sprintf("           %s  %s  \n",x['private_ip'],x['name'])
  end

  tfn = "templates/playbook/coredns-configmap.yaml.template"
  ofn = "playbook/addon_coredns/templates/coredns-configmap.yaml"
  $file_list.push(ofn)  
  File.open(tfn, "r") do |f|
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /^__DNS_ENTRY__/
          w.write dns_entry
        else
          w.write line
        end
      }
    end
  end
  
end

##
## ノードのロールラベル設定 role_worker.yaml
## Set role to node
##
def set_node_role()

  ofn = "playbook/tasks/role_worker.yaml"
  $file_list.push(ofn)  
  File.open(ofn, "w") do |w|
    w.write $insert_msg
    w.write <<EOF
- name: Set node role
  shell: |
EOF
    $vm_config_array.each do |val|
      x = eval(val)
      if x['role'] != nil and !(x['name'] =~ /^master*/)        
        w.write sprintf("%skubectl label node %s --overwrite=true node-role.kubernetes.io/%s=\'\'\n",
                        "\s"*4, x['name'], x['role'])
        w.write sprintf("%skubectl label node %s --overwrite=true role=%s-node\n",
                        "\s"*4, x['name'], x['role'])
        if x['role'] =~ /^proxy*/
          w.write sprintf("%skubectl taint node %s --overwrite=true node-role.kubernetes.io/%s=\'\':NoSchedule\n",
                          "\s"*4, x['name'], x['role'])

        end
      end
    end
    
    w.write <<EOF
  args:
    chdir: "/home/{{ cluster_admin }}"
  become: true
  become_user: "{{ cluster_admin }}"
EOF
  end
end

##
## ノードのロールラベル設定 role_worker.yaml
## Set role to node
##
def set_role_added_node()
  ofn = "playbook/tasks/role_worker_add.yaml"
  $file_list.push(ofn)
  File.open(ofn, "w") do |w|
    w.write $insert_msg
    w.write <<EOF
- name: Set role to added node
  shell: |
    x=(`kubectl get node {{ item.name }} -o json |jq .metadata.labels.role`)
    if [ $x == null ]
    then
      kubectl label node {{ item.name }} --overwrite=true node-role.kubernetes.io/worker=""
      kubectl taint node {{ item.name }} --overwrite=true role=worker-node
    fi
  args:
    chdir: "/home/{{ cluster_admin }}"
    executable: /bin/bash
  when: item.name is match("node*")
  loop: "{{ nodes }}"
  become: true
  become_user: "{{ cluster_admin }}"
EOF

  end
end

##
## 証明書の対象ホストのリスト作成
## playbook/cert_setup/tasks/k8s-cert.yaml
##
def k8s_cert()

  # マスターノードと内部ロードバランサーのリスト作成
  list_all = (host_list("master",0,0).length == 0 ? "" : host_list("master",0,0)) \
             + (host_list("master",1,0).length == 0 ? "" : "," + host_list("master",1,0)) \
             + (host_list("master",2,0).length == 0 ? "" : "," + host_list("master",2,0)) \
             + (host_list("mlb",0,0).length == 0 ? "" : "," + host_list("mlb",0,0)) \
             + (host_list("mlb",1,0).length == 0 ? "" : "," + host_list("mlb",1,0)) \
             + ($conf['kube_apiserver_vip'].length == 0 ? "" : "," + $conf['kube_apiserver_vip']) \
             + ($conf['front_proxy_vip'].nil? ? "" : "," + $conf['front_proxy_vip']) \
             + ",10.32.0.1,127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc" \
             + ",kubernetes.default.svc." + $sub_domain \
             + ",kubernetes.default.svc." + $domain

#             + ",kubernetes.default.svc.cluster" \
#             + ",kubernetes.default.svc.cluster.local"

  
  
  #printf("\n証明書対象リスト %s\n", list_all)
  ofn = "playbook/cert_setup/vars/main.yaml"
  $file_list.push(ofn)  
  File.open(ofn, "a") do |w|
    w.write sprintf("host_list_k8sapi: %s\n",list_all)
  end
end

##
## ストレージサーバーのリストを埋め込む
##
def create_storage_node_taint(server_list)
  tfn = "templates/playbook/set_taint_label_for_storage.yaml.template"
  ofn = "playbook/tasks/role_storage.yaml"
  File.open(tfn, "r") do |f|
    $file_list.push(ofn)    
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /^__SERVER_LIST__/
          w.write server_list
        else
          w.write line
        end
      }
    end
  end
end




##
## ノードにラベルを追加する
##
def node_label_task()

  tfn = "templates/playbook/set-node-label.yaml.template"
  ofn = "playbook/tasks/add-node-label.yaml"
  command_list = ""
  
  $vm_config_array.each do |val|
    x = eval(val)
    if x['node_label']
      x['node_label'].each do |val|
        val.class
        val.each do |key,val|
          command_list = command_list + sprintf("%skubectl label node %s --overwrite=true %s=%s\n","\s"*4,x['name'],key,val)
        end
      end
    end
  end

  File.open(tfn, "r") do |f|
    $file_list.push(ofn)    
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /^__ADD_NODELABEL_LIST__/
          w.write command_list
        else
          w.write line
        end
      }
    end
  end
end

###############################################################

##
## メイン処理
##

if __FILE__ == $0

  ## コマンド引数の取得
  arg_state = nil
  ARGV.each_with_index do |arg, i|
    if arg_state == nil
      arg_state = arg
    else
      if arg_state == "-f"
        $config_yaml = arg
      elsif arg_state == "-s"
        if arg == "auto"
          $auto_start = true
        end
      elsif arg_state == "-m"
        $mode = arg
      elsif arg_state == "-p"
        if arg == "auto"
          $search_ip = true          
        end
      end
      arg_state = nil
    end
  end


  $hypervisor_os = get_os_kind

  ## Vagarntの仮想サーバースペックを作成
  ## 及び、メモリ編集に取り込み
  printf("ファイル名: %s\n",$config_yaml)
  step_start("コンフィグファイルの読み取り")
  vm_config = read_yaml_config($config_yaml)
  step_end( vm_config.length > 0 ? 0 : 1 )

  if $mode == "test"
    puts vm_config
    exit!
  end

  
  ## IP アドレスのチェックと空きアドレスのアサイン
  if $search_ip
    step_start("空きIPアドレスのスキャン")
    overwrite_node_ip()
    overwrite_vip_ip()
    step_end(0)
    vm_config = "vm_spec = " \
    + $vm_config_array.to_s.gsub('=>', ':').to_s.gsub('\\', '').to_s.gsub('"{', '{').to_s.gsub('}"', '}')    
  end


  ## テンプレートを読み込んで、Vagrantfileを生成
  step_start("Vagrantfileの書き出し")
  linenum = 1
  tfn = "templates/vagrant/Vagrantfile.template"
  ofn = "Vagrantfile"
  $file_list.push(ofn)  
  File.open(tfn, "r") do |f|
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("#\n")      
      w.write sprintf("### Template file is %s\n",tfn)
      w.write sprintf("###   Config file is %s\n",$config_yaml)
      w.write sprintf("#\n")
      f.each_line { |line|
        if line =~ /^__VM_CONFIG__/
          w.write vm_config
        else
          w.write line
        end
      }
    end
  end
  step_end(0)


  
  ## Ansibleインベントリ書き出し
  step_start("Ansible インベントリ書き出し")
  output_ansible_inventory()
  step_end(0)

  ## KVM 環境用
  #if $conf['hypervisor'] == 'kvm'
  #  step_start("virt-installシェルの書き出し")
  #  step_end(0)
  #end
  
  
  printf("ノード構成\n")
  printf("マスターノード   = %d\n", $cnt['master'])
  printf("ワーカーノード   = %d\n", $cnt['node'])  
  #printf("プロキシノード   = %d\n", $cnt['proxy'])  
  printf("ストレージノード = %d\n", $cnt['storage'])  
  printf("マスター用LB     = %d\n", $cnt['mlb'])
  printf("外部LB           = %d\n", $cnt['elb'])  
  printf("監視用ノード     = %d\n", $cnt['mon'])  

  if $conf['hypervisor'].nil? or $conf['hypervisor'] == 'vv'
    $conf['hypervisor'] = 'vv'
    $conf['cluster_admin'] = 'vagrant'
    $conf['shared_fs'] = '/vagrant'
    $conf['iface'] = 'enp0s8'
    $conf['internal_ipv4_address'] = "{{ ansible_facts.enp0s8.ipv4.address }}"
  elsif $conf['hypervisor'] == 'kvm'
    $conf['cluster_admin'] = 'ubuntu'
    $conf['shared_fs'] = '/srv'
    $conf['iface'] = 'enp1s0'
    $conf['internal_ipv4_address'] = "{{ ansible_facts.enp1s0.ipv4.address }}"
  elsif $conf['hypervisor'] == 'hv'
    $conf['cluster_admin'] = 'ubuntu'
    $conf['shared_fs'] = '/srv'
    $conf['iface'] = 'eth1'
    $conf['internal_ipv4_address'] = "{{ ansible_facts.eth1.ipv4.address }}"    
  end
  
  printf("HyperVisor       = %s\n", $conf['hypervisor'])

  
  
  ## ansible変数としてノードのリスト作成、hostsファイル作成
  step_start("ノードリストの変数作成")
  vars_nodelist()
  step_end(0)
  
  step_start("/etc/hosts テンプレート作成")
  create_hosts_file()
  step_end(0)
  
  step_start("etcd.service テンプレート作成")
  etcd_service()
  step_end(0)

  step_start("etcd の playbook 作成")  
  etcd_yaml()
  step_end(0)

  step_start("kube-apiserver テンプレート作成")  
  kube_apiserver_service()
  step_end(0)

  step_start("証明書の対象ホストのリスト作成")
  k8s_cert()
  step_end(0)

  step_start("マスター用Load Balancer設定作成")
  haproxy_cfg()
  step_end(0)

  step_start("フロント用oLoad Balancer設定作成")
  haproxy_front_cfg()
  step_end(0)

  step_start("CoreDNS エントリー追加")
  coredns_config()
  step_end(0)
  
  ## ルーティング設定
  step_start("Pod Network ブリッジで構成")
  create_static_network_route()
  step_end(0)

  step_start("Pod Network Ubuntu18.04 netplan")  
  create_ubuntu_static_routing()
  step_end(0)

  step_start("Pod Network 10-bridge.conf設定")
  create_bridge_conf()
  step_end(0)
  
  ## Worker ノードへロールをセット
  step_start("ノード role設定 role_worker.yaml")
  set_node_role()
  step_end(0)

  step_start("追加ノード role設定 role_worker_add.yaml")
  set_role_added_node()
  step_end(0)
  
  ## ストレージノードのリストセット
  step_start("ストレージノードのラベル設定")
  list_storage = list_by_role("storage")
  create_storage_node_taint(list_storage)
  step_end(0)

  
  ## ノードラベル追加設定
  step_start("ノード・ラベルの追加処理")  
  node_label_task()
  step_end(0)
  
  ## 変数追加
  step_start("Ansible playbookに変数追加")

  if $conf['hypervisor'] == "vv" 
    append_ansible_inventory("hosts_k8s")
    append_ansible_inventory("hosts_vagrant")  
  elsif $conf['hypervisor'] == 'kvm'
    append_ansible_inventory("hosts_kvm")
    append_ansible_inventory("hosts_local")
  elsif $conf['hypervisor'] == 'hv'
    append_ansible_inventory("hosts_hv")
    append_ansible_inventory("hosts_local")    
  end

  step_end(0)

  ## 自動起動
  if $auto_start
    ## 仮想マシン起動
    system('vagrant up')
  end
end 

printf("\n *** 書き出したファイルのリスト *** \n")
puts $file_list
printf("\n *** NODE IP リスト *** \n")
list_node_ip()
printf("*** End of list ***\n")
