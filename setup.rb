#!/usr/bin/ruby
# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# 起動前にモジュールを追加しておく
# $ sudo gem install mb_string
#



require 'mb_string'
require 'yaml'
require 'json'

$insert_msg  = "### THIS FILE IS GENERATED BY setup.rb ###\n"
$domain = nil
$exist_proxy_node = nil
$exist_storage_node = nil
$mode = nil
$single_node = nil

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
## YAML環境ファイルの読み込み
##  グローバル変数 $conf、
##  Vagrantrfile へ設定書き込み
##  デフォルト値を上書きする形にする
## 
def read_yaml_config(file)
  $vm_config_array = []
  i = 10
  begin
    $conf = YAML.load_file(file)
    cnf = "vm_spec = [\n"
    $conf.class
    $domain = $conf['domain']  
    $conf.each do |key1, val1|
      # VMスペックの読み込み
      if val1.class == Array and key1 == "vm_spec"
        $conf[key1].each do |val2|
          wk = {}
          val2.each do |key3, val3|
            if val3 != nil
              wk[key3] = val3
            end
          end
          # public_ipが存在しない場合はwkで補完しない。
          if !(val2.has_key?('public_ip'))
            wk.delete('public_ip')
          end
          cnf = cnf + wk.to_json + ",\n"
          $vm_config_array.push(wk.to_s)
        end
      end    
    end
    return cnf + "]\n"
  rescue
    return ""
  end
end


##
## ホスト名からIPアドレス取得
##
##
def get_ip_by_host(hostname)
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] == hostname
      return x['public_ip'], x['private_ip']
    end
  end
  return nil,nil
end


##
## ポッドネットワークをブリッジで構成時
##   各ノードのブリッジ設定 10-bridge.conf
##
def create_bridge_conf()
  $vm_config_array.each do |val|
    x = eval(val)
    if x['pod_network'] != nil
      n = x['pod_network'].split(/\./)
      subnet = sprintf("%d.%d.%d.0/24", n[0],n[1],n[2])
      range_start = sprintf("%d.%d.%d.%d", n[0],n[1],n[2],2)
      range_end = sprintf("%d.%d.%d.%d", n[0],n[1],n[2],253)
      gateway   = sprintf("%d.%d.%d.%d", n[0],n[1],n[2],254)

      ofn = sprintf("playbook/net_bridge/templates/10-bridge.conf.%s", x['name'])
      File.open("templates/playbook/10-bridge.conf.template", "r") do |f|
        $file_list.push(ofn)
        File.open(ofn, "w") do |w|
          #w.write $insert_msg # JSON形式なのでコメントが書けない
          f.each_line { |line|
            if line =~ /^__SET_CONFIG__/
              w.write sprintf("%s\"%s\": \"%s\",\n", "\s"*16, "subnet",    subnet)
              w.write sprintf("%s\"%s\": \"%s\",\n", "\s"*16, "rangeStart",range_start)
              w.write sprintf("%s\"%s\": \"%s\",\n", "\s"*16, "rangeEnd",  range_end)
              w.write sprintf("%s\"%s\": \"%s\" \n", "\s"*16, "gateway",   gateway)
            else
              w.write line
            end
          }
        end
      end
    end
  end
end

##
##  ポッドネットワークをブリッジで構成時
##  ワーカノードのIPマスカレード設定
##
def iptables_by_worker(node)
  rst = ""
  $vm_config_array.each do |val|
    x = eval(val)
    if x['pod_network'] != nil
      if node == x['name'] 
        rst = rst + sprintf("  shell: iptables -t nat -A POSTROUTING -s %s -j MASQUERADE\n", x['pod_network'])
      end
    end
  end
  return rst
end

##
## ポッドネットワークをブリッジで構成時
##   ワーカーノードのルーティング設定
##
def routing_by_worker(node)
  rst = ""
  $vm_config_array.each do |val|
    x = eval(val)
    if x['pod_network'] != nil
      if node != x['name'] 
        rst = rst + sprintf("%s - to: %s\n",        "\s"*11, x['pod_network'])
        rst = rst + sprintf("%s   via: %s\n",       "\s"*11, x['private_ip'])
        rst = rst + sprintf("%s   metric: 100\n",   "\s"*11) 
        rst = rst + sprintf("%s   on-link: true\n", "\s"*11) 
      end
    end
  end
  return rst
end


##
## ポッドネットワークをブリッジで構成時
## 　ルーティング設定
## playbook/net_bridge/tasks/static-route-{{ item.name }}.yaml
##
def create_static_network_route()
  $vm_config_array.each do |val|
    x = eval(val)

    if x['pod_network'] != nil
      rst1 = routing_by_worker(x['name'])
      rst2 = iptables_by_worker(x['name'])

      ## ワーカーノードが一つの場合の設定が必要
      tfn = "templates/playbook/net_bridge_static-route_iptables.yaml.template"
      if rst1 == ""
        tfn = "templates/playbook/net_bridge_iptables.yaml.template"
      end
      ofn = sprintf("playbook/net_bridge/tasks/static-route-%s.yaml",x['name'])
      $file_list.push(ofn)
      File.open(tfn, "r") do |f|
        File.open(ofn, "w") do |w|
          w.write $insert_msg
          w.write sprintf("### Template file is %s\n",tfn)
          f.each_line { |line|
            if line =~ /^__SET_ROUTING__/
              w.write rst1
            elsif line =~ /^__SET_IPTABLES__/
              w.write rst2              
            else
              w.write line
            end
          }
        end
      end
    end
  end
end


##
## ポッドネットワークをブリッジで構成時
## 　ルーティング設定
##   playbook/net_bridge/tasks/static-route.yaml
##
def create_ubuntu_static_routing()

  tfn = "templates/playbook/net_bridge_static-route.yaml.template"
  ofn = "playbook/net_bridge/tasks/static-route.yaml"
  File.open(tfn, "r") do |f|
    $file_list.push(ofn)
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /^__SET_ROUTING__/
          $vm_config_array.each do |val|
            x = eval(val)
            if x['pod_network'] != nil
              w.write sprintf("%s - to: %s\n",        "\s"*11,  "10.32.0.0/24")
              w.write sprintf("%s   via: %s\n",       "\s"*11,  x['private_ip'])
              w.write sprintf("%s   metric: 100\n",   "\s"*11)
              w.write sprintf("%s   on-link: true\n", "\s"*11)              
            end
          end

          $vm_config_array.each do |val|
            x = eval(val)
            if x['pod_network'] != nil
              w.write sprintf("%s - to: %s\n",        "\s"*11,  x['pod_network'])
              w.write sprintf("%s   via: %s\n",       "\s"*11,  x['private_ip'])
              w.write sprintf("%s   metric: 100\n",   "\s"*11)
              w.write sprintf("%s   on-link: true\n", "\s"*11)              
            end
          end
        else
          w.write line
        end
      }
    end
  end
end

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
      w.write sprintf("%-20s %-16s %-20s\n",x['private_ip'], x['name'], x['name'] + "." + $domain)
    end
  end
end


##
## ノードのロールでリストする
##  
##
def list_by_role(role)
  rst = ""
  $vm_config_array.each do |val|
    x = eval(val)
    if x['role'] != nil
      if role == x['role'] 
        rst = rst + sprintf("%s- %s\n", "\s"*4, x['name'])
      end
    end
  end
  return rst
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
            if x.has_key?('public_ip')
              w.write sprintf("  - { name: %-10s, pub_ip: %-15s, pri_ip: %-15s }\n",
                              "'" + x['name'] + "'",
                              "'" + x['public_ip'] + "'",
                              "'" + x['private_ip'] + "'")
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

##
## Ansibleインベントリ・テンプレート #1  hosts_vagrant
##
##
def output_ansible_inventory0(ofn,sw)
  counter_master  = 0
  counter_node    = 0
  counter_proxy   = 0
  counter_storage = 0
  counter_mlb     = 0
  counter_elb     = 0
  counter_boot    = 0
  counter_sum     = 0   

  tfn = "templates/ansible/hosts_vagrant.template"
  File.open(tfn, "r") do |f|
    $file_list.push(ofn)
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("#\n### Template file is %s\n#\n", tfn)
      
      # コンフィグからそれぞれのノードをカウントする。
      $vm_config_array.each do |val|
        x = eval(val)
        if x['name'] == "bootnode"
          counter_boot += 1
          counter_sum += 1          
          w.write sprintf("%-20s %s\n", x['name'], "ansible_connection=local")
        else
          if x['name'] =~ /^node*/
            counter_node += 1
            counter_sum += 1
          elsif x['name'] =~ /^master*/
            counter_master += 1
            counter_sum += 1            
          elsif x['name'] =~ /^proxy*/
            counter_proxy += 1
            counter_sum += 1            
          elsif x['name'] =~ /^storage*/
            counter_storage += 1
            counter_sum += 1            
          elsif x['name'] =~ /^mlb*/
            counter_mlb += 1
            counter_sum += 1            
          elsif x['name'] =~ /^elb*/
            counter_elb += 1
            counter_sum += 1            
          end
          if sw == 0
            w.write sprintf("%-20s  %s\n", x['name'], "ansible_connection=local")
          else
            w.write sprintf("%-20s ansible_ssh_host=%s  ansible_ssh_private_key_file=/vagrant/keys/id_rsa\n", x['name'],x['name'])
          end
        end
      end
      $exist_proxy_node = (counter_proxy > 0)
      $exist_storage_node = (counter_storage > 0)
      $cnt['node']    = counter_node
      $cnt['master']  = counter_master
      $cnt['proxy']   = counter_proxy
      $cnt['storage'] = counter_storage
      $cnt['mlb']     = counter_mlb
      $cnt['elb']     = counter_elb
      $cnt['boot']    = counter_boot

      # ノード合計値
      $single_node = ( counter_sum == 1)
      if $single_node
        $cnt['master'] = 0
        counter_master = 0        
      end
      
      w.write "\n\n"

      # 文字列マッチでテンプレートを置換
      f.each_line { |line|
        if line =~ /^node\[1:/
          w.write sprintf("node[1:%d]\n",counter_node)

        elsif line =~ /^master\[1:/
          w.write sprintf("master[1:%d]\n",counter_master)

        elsif line =~ /^proxy\[1:/
          w.write sprintf("proxy[1:%d]\n",counter_proxy)
          
        elsif line =~ /^storage\[1:/
          w.write sprintf("storage[1:%d]\n",counter_storage)
          
        elsif line =~ /^mlb\[1:/
          w.write sprintf("mlb[1:%d]\n",counter_mlb)

        elsif line =~ /^elb\[1:/
          w.write sprintf("elb[1:%d]\n",counter_elb)
          
        elsif line =~ /__KUBERNETES_VERSION__/
          w.write sprintf("kubernetes_version=\"v%s\"\n", $conf['kubernetes_version'])
          w.write sprintf("kubernetes_version_ubuntu=\"=%s-00\"\n", $conf['kubernetes_version'])
          if $conf['kubernetes_custom'] == true
            w.write sprintf("custom_kubernetes=true\n")
          else
            w.write sprintf("custom_kubernetes=false\n")
          end

        elsif line =~ /__WORK_DIR__/
          if counter_boot == 0
            w.write line.gsub(/__WORK_DIR__/, '{{ work_dir }}')
          else
            w.write line.gsub(/__WORK_DIR__/, '/mnt')
          end

        elsif line =~ /__SINGLE_NODE__/
          if counter_sum == 1
            w.write line.gsub(/__SINGLE_NODE__/, 'master')
          end
          
        elsif line =~ /__POD_NETWORK__/
          w.write line.gsub(/__POD_NETWORK__/, $conf['pod_network'])
          
        elsif line =~ /__FLANNEL_VER__/
          if $conf['flannel_version'].nil? == false
            w.write line.gsub(/__FLANNEL_VER__/, $conf['flannel_version'])
          end
          
        elsif line =~ /__API_SERVER_IPADDR__/
          w.write line.gsub(/__API_SERVER_IPADDR__/, $conf['kube_apiserver_vip'])
          
        elsif line =~ /__MLB_IP_PRIMALY__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_primary_internal_host'])
          w.write line.gsub(/__MLB_IP_PRIMALY__/, priv_ip.to_s)
          
        elsif line =~ /__MLB_IP_BACKUP__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_backup_internal_host'])
          w.write line.gsub(/__MLB_IP_BACKUP__/, priv_ip.to_s)

        elsif line =~ /__FRONTEND_IPADDR__/
          # elbを検索して存在しなければパスする
          $vm_config_array.each do |val|
            x = eval(val)
            if x['name'] =~ /elb*/
              w.write line.gsub(/__FRONTEND_IPADDR__/, $conf['front_proxy_vip'])
            end
          end

        elsif line =~ /__ELB_IP_PRIMALY__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_primary_frontend_host'])
          w.write line.gsub(/__ELB_IP_PRIMALY__/, pub_ip.to_s)
          
        elsif line =~ /__ELB_IP_BACKUP__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_backup_frontend_host'])
          w.write line.gsub(/__ELB_IP_BACKUP__/, pub_ip.to_s)
          
        else
          w.write line
          
        end
      }
    end
  end
end

##
## Ansible インベントリファイルの出力
##   Vagrant から起動する初期化用
##   ノードから起動するK8sセットアップ用
##
def output_ansible_inventory()
  output_ansible_inventory0("hosts_k8s", 1)
  output_ansible_inventory0("hosts_vagrant", 0)
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
    chdir: /home/vagrant
  become: true
  become_user: vagrant
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
    chdir: /home/vagrant
    executable: /bin/bash
  when: item.name is match("node*")
  loop: "{{ nodes }}"
  become: true
  become_user: vagrant
EOF

  end
end


##
##  IP or ホスト名 リスト作成
##    第一引数 ホスト名先頭一致部分
##    第二引数 ホスト or IPアドレスのスイッチ
##              sw = 0     sw = 1
##    第三引数 0より大きな値を入れると https://?:opが設定
##
def host_list(hostname,sw,op)
  n = 0
  host_list = ""
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] =~ /^#{hostname}*/
      w = ""
      if sw == 0
        w = x['name']
      elsif sw == 1
        w = x['private_ip']
      elsif sw == 2
        if x['public_ip'].nil? == false
          w = x['public_ip']
        end
      end
      if op > 0
        w = "https://" + w + sprintf(":%d",op)
      end
      if n == 0
        host_list = w
      else
        if w.length > 0
          host_list = host_list + "," + w
        end
      end
      n = n + 1
    end
  end
  return host_list
end


##
## マスターノードのhost_list を生成する
##
##
def coredns_host_ip_list()
  
  hostnames = host_list("master",0,0).split(",")
  urls = host_list("master",1,2380).split(",")

  param = ""
  hostnames.each_with_index do |val, i|
    if i.to_i > 0
      param = param + ","
    end
    param = param + sprintf("%s=%s", hostnames[i],urls[i])
  end
  return param
  
end


## 
## etcd のアドレスで置き換える
## playbook/node_master/templates/kube-apiserver.service.j2
##
def kube_apiserver_service()

  host_list = host_list("master",1,2379)

  tfn = "templates/playbook/kube-apiserver.service.j2.template"
  ofn = "playbook/node_master/templates/kube-apiserver.service.j2"
  $file_list.push(ofn)
  
  File.open(tfn, "r") do |f|  
    File.open(ofn , "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /__ETCD_LIST__/
          #puts host_list
          w.write line.gsub(/__ETCD_LIST__/, host_list)
        elsif line =~ /__APISERVER_COUNT__/
          api_server_count = 1
          if $cnt['master'] > 0
            api_server_count = $cnt['master']
          end
          w.write line.gsub(/__APISERVER_COUNT__/, sprintf("%d", api_server_count))
        else
          w.write line
        end
      }
    end
  end

end

##
## etcdのクラスタメンバーのIPアドレス設定
## playbook/etcd/templates/etcd.service.j2
##
def etcd_service()

  host_list = coredns_host_ip_list()
  tfn = "templates/playbook/etcd.service.j2.template"
  ofn = "playbook/etcd/templates/etcd.service.j2"
  $file_list.push(ofn)
  File.open(tfn, "r") do |f|  
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /__ETCD_LIST__/
          w.write line.gsub(/__ETCD_LIST__/, host_list)            
        else
          w.write line
        end
      }
    end
  end
end

##
## etcd.yam
##  playbook/cert_setup/tasks/etcd.yaml
##
def etcd_yaml()

  # マスターノードと内部ロードバランサーのリスト作成
  list_mst = host_list("master",0,0) + "," + host_list("master",1,0) 
  list_mlb = host_list("mlb",0,0) + "," + host_list("mlb",1,0)  
  list_all = list_mst + "," + list_mlb

  list_all = (host_list("master",0,0).length == 0 ? "" : host_list("master",0,0)) \
             + (host_list("master",1,0).length == 0 ? "" : "," + host_list("master",1,0)) \
             + (host_list("mlb",0,0).length == 0 ? "" : "," + host_list("mlb",0,0)) \
             + (host_list("mlb",1,0).length == 0 ? "" : "," + host_list("mlb",1,0)) \
             + ",10.32.0.1,127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local"

  ofn = "playbook/cert_setup/vars/main.yaml"
  $file_list.push(ofn)  
  File.open(ofn, "w") do |w|
    w.write sprintf("host_list_etcd: %s\n",list_all)
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
             + ",10.32.0.1,127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local"
  
  #printf("\n証明書対象リスト %s\n", list_all)
  ofn = "playbook/cert_setup/vars/main.yaml"
  $file_list.push(ofn)  
  File.open(ofn, "a") do |w|
    w.write sprintf("host_list_k8sapi: %s\n",list_all)
  end
end


## マスターノード用ロードバランサー
## playbook/haproxy/templates/haproxy.cfg.j2
##
def haproxy_cfg()

  server_list = ""
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] =~ /^master*/
      server_list = server_list + sprintf("%s server %s %s:6443 check\n", "\s"*4, x['name'], x['private_ip'])
    end
  end

  tfn = "templates/playbook/haproxy.cfg.j2.template"
  ofn = "playbook/haproxy/templates/haproxy_internal.cfg.j2"
  $file_list.push(ofn)
  
  File.open(tfn, "r") do |f|
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


## フロント用ロードバランサー
## playbook/haproxy/templates/haproxy_frontend.cfg.j2.template
##
def haproxy_front_cfg()

  ofn = "playbook/haproxy/templates/haproxy_frontend.cfg.j2"
  tfn = "templates/playbook/haproxy_frontend.cfg.j2.template"  

  server_list_node = ""
  server_list_api = ""  
  $vm_config_array.each do |val|
    x = eval(val)
    ## ワーカーノード
    if x['name'] =~ /^node*/
      if x['role'] =~ /^worker/
        server_list_node = server_list_node + sprintf("%s server %s %s:30443 check\n", "\s"*4, x['name'], x['private_ip'])
      end
    end
    if x['name'] =~ /^master*/
      server_list_api = server_list_api + sprintf("%s server %s %s:6443 check\n", "\s"*4, x['name'], x['private_ip'])
    end
  end
  
  $file_list.push(ofn)  
  
  File.open(tfn, "r") do |f|
    File.open(ofn, "w") do |w|
      w.write $insert_msg
      w.write sprintf("### Template file is %s\n",tfn)
      f.each_line { |line|
        if line =~ /^__SERVER_LIST_APL__/
          w.write server_list_node
        elsif line =~ /^__SERVER_LIST_API__/
          w.write server_list_api
        else
          w.write line
        end
      }
    end
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
##
##
def append_ansible_inventory(ofn)
  $file_list.push(ofn)  
  File.open(ofn, "a") do |w|
    w.write sprintf("\n")
    w.write sprintf("proxy_node=%s\n", $exist_proxy_node)
    w.write sprintf("storage_node=%s\n", $exist_storage_node)
    w.write sprintf("domain=%s\n", $domain)
    w.write sprintf("internal_subnet=%s\n", $conf['private_ip_subnet'])
    w.write sprintf("domain=%s\n", $domain)
    w.write sprintf("single_node=%s\n", $single_node)
    w.write sprintf("\n")    
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

##
## ステップの開始
##
def step_start(msg)
  xmsg = "\u001b[33m" + msg + "\u001b[49m "
  printf("%s", xmsg.mb_ljust(70,'*'))
end

##
## 終了
##
def step_end(ret)
  if ret == 0
    printf(" [\u001b[32m完了\u001b[49m\u001b[33m]\u001b[49m\n")
  else
    printf(" [\u001b[31m失敗\u001b[49m\u001b[33m]\u001b[49m\n")
    exit(1)
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
      end
      arg_state = nil
    end
  end


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
  
  printf("ノード構成\n")
  printf("マスターノード   = %d\n", $cnt['master'])
  printf("ワーカーノード   = %d\n", $cnt['node'])  
  #printf("プロキシノード   = %d\n", $cnt['proxy'])  
  printf("ストレージノード = %d\n", $cnt['storage'])  
  printf("マスター用LB     = %d\n", $cnt['mlb'])
  printf("外部LB           = %d\n", $cnt['elb'])  
  printf("監視用ノード     = %d\n", $cnt['mon'])  

  
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
  append_ansible_inventory("hosts_k8s")
  step_end(0)

  ## 自動起動
  if $auto_start
    ## 仮想マシン起動
    system('vagrant up')
  end
end 

printf("\n *** 書き出したファイルのリスト *** \n")
puts $file_list 
printf("*** End of list ***\n")
