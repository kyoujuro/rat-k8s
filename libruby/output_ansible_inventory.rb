# coding: utf-8
##
## Ansible インベントリファイルの出力
##   Vagrant から起動する初期化用
##   ノードから起動するK8sセットアップ用
##
def output_ansible_inventory()
  if $conf['hypervisor'] == "vv" 
    output_ansible_inventory0("hosts_k8s", 1)
    output_ansible_inventory0("hosts_vagrant", 0)
  elsif $conf['hypervisor'] == 'kvm'
    output_ansible_inventory0("hosts_kvm", 2)
  elsif $conf['hypervisor'] == 'hv'
    output_ansible_inventory0("hosts_hv", 3)
  else
    printf("Abort due to undfined hypervisor\n")
    exit!
  end
end


##
## Ansibleインベントリ・テンプレート #1  hosts_vagrant
##  env_sw
##    0 : ansible local
##    1 : ansible remote on vagarnt / virtualbox
##    2 : ansible remote on virsh / kvm
##    3 : ansible remote on windows hyper-v
##
def output_ansible_inventory0(ofn,env_sw)
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
          if env_sw == 1
            w.write sprintf("%-20s ansible_ssh_host=%s  ansible_ssh_private_key_file=/vagrant/keys/id_rsa\n", x['name'],x['name'])            
          elsif env_sw == 2 or env_sw == 3
            w.write sprintf("%-20s ansible_ssh_host=%s  ansible_ssh_private_key_file=/root/.ssh/id_rsa\n", x['name'],x['name']) 
          else
            w.write sprintf("%-20s  %s\n", x['name'], "ansible_connection=local")
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
          
        #elsif line =~ /__KUBERNETES_VERSION__/
        #  w.write sprintf("kubernetes_version=\"v%s\"\n", $conf['kubernetes_version'])
        #  #w.write sprintf("kubernetes_version_ubuntu=\"=%s-00\"\n", $conf['kubernetes_version'])
        #  if $conf['kubernetes_custom'] == true
        #    w.write sprintf("custom_kubernetes=true\n")
        #  else
        #    w.write sprintf("custom_kubernetes=false\n")
        #  end

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
          
        #elsif line =~ /__POD_NETWORK__/
        #  w.write line.gsub(/__POD_NETWORK__/, $conf['pod_network'])
          
        #elsif line =~ /__FLANNEL_VER__/
        #  if $conf['flannel_version'].nil? == false
        #    w.write line.gsub(/__FLANNEL_VER__/, $conf['flannel_version'])
        #  end

        elsif line =~ /__API_SERVER_IPADDR__/
          w.write line.gsub(/__API_SERVER_IPADDR__/, $conf['kube_apiserver_vip'])
          
        elsif line =~ /__MLB_IP_PRIMALY__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_primary_internal_host'])
          w.write line.gsub(/__MLB_IP_PRIMALY__/, priv_ip.to_s)
          
        elsif line =~ /__MLB_IP_BACKUP__/
          pub_ip,priv_ip = get_ip_by_host($conf['ka_backup_internal_host'])
          w.write line.gsub(/__MLB_IP_BACKUP__/, priv_ip.to_s)

        elsif line =~ /__FRONTEND_IPADDR__/
          # elb1を検索して存在しなければパスする
          $vm_config_array.each do |val|
            x = eval(val)
            if x['name'] =~ /elb1/
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
## Ansible Inventory に変数を追加する
##
def print_nn(w,param)
  if $conf[param].nil?
    return
  else
    if $conf[param] == true or $conf[param] == false
      w.write sprintf("%s = %s\n", param, $conf[param].to_s.capitalize)
    else
      w.write sprintf("%s = %s\n", param, $conf[param])
    end
    #if !!$conf[param]
    #  # Boolean
    #  w.write sprintf("%s = %s\n", param, $conf[param].to_s.capitalize)
    #else
    #  # 文字型
    #  w.write sprintf("%s = %s\n", param, $conf[param])
    #end
  end
end

def append_ansible_inventory(ofn)
  $file_list.push(ofn)  
  File.open(ofn, "a") do |w|
    w.write sprintf("\n")
    print_nn(w,'hypervisor')
    print_nn(w,'iface')
    print_nn(w,'internal_ipv4_address')
    print_nn(w,'cluster_admin')
    print_nn(w,'shared_fs')
    print_nn(w,'cpu_arch')
    print_nn(w,'kubernetes_version')
    print_nn(w,'kubernetes_custom')    
    #w.write sprintf("custom_kubernetes = %s\n",$conf['custom_kubernetes'] == true ? "yes" : "no")
    print_nn(w,'kubernetes_dashborad_ver')
    print_nn(w,'kubernetes_metrics_server')
    print_nn(w,'etcd_version')
    print_nn(w,'keepalived_version')
    if !$conf['front_proxy_vip'].nil?
      $conf['front_proxy_vip_nomask'] = $conf['front_proxy_vip']
      print_nn(w,'front_proxy_vip_nomask')
    end
    print_nn(w,'istio_gateway_vip')
    w.write sprintf("proxy_node = %s\n", $exist_proxy_node.to_s.capitalize)
    w.write sprintf("storage_node = %s\n", $exist_storage_node.to_s.capitalize)
    print_nn(w,'domain')
    print_nn(w,'sub_domain')
    print_nn(w,'pod_network')

    host_sub_domain = sprintf("kubernetes.default.svc.%s",$domain)
    host_domain = sprintf("kubernetes.default.svc.%s",$sub_domain)
    #w.write sprintf("host_list_etcd = %s,%s,%s,%s,%s,%s,%s\n","10.32.0.1","127.0.0.1","kubernetes","kubernetes.default","kubernetes.default.svc","kubernetes.default.svc.cluster","kubernetes.default.svc.cluster.local")
    #w.write sprintf("host_list_k8sapi = %s,%s,%s,%s,%s,%s,%s\n","10.32.0.1","127.0.0.1","kubernetes","kubernetes.default","kubernetes.default.svc","kubernetes.default.svc.cluster","kubernetes.default.svc.cluster.local")
    w.write sprintf("host_list_etcd = %s,%s,%s,%s,%s,%s,%s\n","10.32.0.1","127.0.0.1","kubernetes","kubernetes.default","kubernetes.default.svc",host_sub_domain,host_domain)
    w.write sprintf("host_list_k8sapi = %s,%s,%s,%s,%s,%s,%s\n","10.32.0.1","127.0.0.1","kubernetes","kubernetes.default","kubernetes.default.svc",host_sub_domain,host_domain)
    
    # private_ip_subnet = internal_subnet として代入
    $conf['internal_subnet'] = $conf['private_ip_subnet']
    print_nn(w,'internal_subnet')
    w.write sprintf("single_node = %s\n",   $single_node.to_s.capitalize)
    w.write sprintf("sw_rook_ceph = %s\n",  $conf['sw_rook_ceph'] == true ? "True" : "False")
    w.write sprintf("sw_promethus = %s\n",  $conf['sw_promethus'] == true ? "True" : "False")
    w.write sprintf("sw_grafana = %s\n",    $conf['sw_grafana'] == true ? "True" : "False")
    w.write sprintf("sw_elk = %s\n",        $conf['sw_elk'] == true ? "True" : "False")
    w.write sprintf("sw_istio = %s\n",      $conf['sw_istio'] == true ? "True" : "False")
    w.write sprintf("sw_knative = %s\n",    $conf['sw_knative'] == true ? "True" : "False")    
    w.write sprintf("sw_use_sdc_cr = %s\n", $conf['sw_use_sdc_cr'] == true ? "True" : "False")         
    w.write sprintf("\n")
    if $conf['container_runtime'].nil?
      $conf['container_runtime'] = "containerd"
    end
    print_nn(w,'container_runtime')
    print_nn(w,'docker_version')
    print_nn(w,'containerd_version')
    print_nn(w,'cni_plugins')
    print_nn(w,'crictl_version')
    print_nn(w,'crio_version')
    print_nn(w,'calico_version')
    print_nn(w,'flannel_version')
    
    w.write sprintf("\n")
  end
end
