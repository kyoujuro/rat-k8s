# coding: utf-8
##
## Ansibleインベントリ・テンプレート #1  hosts_vagrant
##  env_sw
##    0 : ansible local
##    1 : ansible remote on vagarnt / virtualbox
##    2 : ansible remote on virsh / kvm
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
          elsif env_sw == 2
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
