# coding: utf-8
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
