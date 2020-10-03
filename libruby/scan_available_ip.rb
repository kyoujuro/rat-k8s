##
## 空きをスキャン
##
def check_useable_ip(ip_addr)

  $ping_list.each do |node|
    printf(".")
    #printf("check  %s  %s\n",ip_addr,node)
    if node == ip_addr
      return true
    end
  end

  #printf("ping %s ",ip_addr)  
  ip = Net::Ping::External.new(ip_addr);
  if ip.ping == false 
    $ping_list.push(ip_addr)
    #printf("pass\n")
  else
    #printf("faild\n")
  end
  
  return !ip.ping
end


##
## 予約なしをスキャン
##
def check_not_reserve_ip(ip_addr)
  is_exist = false
  is_available = true
  $vm_config_array.each do |val|
    x = eval(val)
    if x['private_ip'] == ip_addr
      is_exist = true
      is_available = false
    end
    if x['public_ip'] == ip_addr
      is_exist = true
      is_available = false
    end
    if $conf['kube_apiserver_vip'] == ip_addr
      is_exist = true
      is_available = false      
    end
    if $conf['front_proxy_vip'] == ip_addr
      is_exist = true
      is_available = false
    end
  end
  #return is_exist
  return is_available
end

##
## 空いているIPアドレスレンジで
## IPアドレスをオーバーライトする
##
def overwrite_node_ip()
  lip = []
  gip = []
  local_ip = nil
  global_ip = nil

  i = 0
  $vm_config_array.each do |val|
    x = eval(val)
    #p x['name']

    # 空きをチェック、なければ避けてチェック
    if x['private_ip'].nil? == false
      lip = conv_strIP_to_numIP(x['private_ip'])
      loop do
        local_ip = sprintf("%s.%s.%s.%s",lip[0],lip[1],lip[2],lip[3])
        if check_useable_ip(local_ip)
          if check_not_reserve_ip(local_ip)
            break
          end
        end
        lip[3] = lip[3] + 1
      end

      # Apiserver VIP とノードIPが同じなら書き換える
      if x['private_ip'] == $conf['kube_apiserver_vip']
        $conf['kube_apiserver_vip'] = local_ip
        $conf['kube_apiserver_vip_correct'] = true
      end
      x['private_ip'] = local_ip
      $vm_config_array[i] = x.to_s
    end

    if x['public_ip'].nil? == false
      gip = conv_strIP_to_numIP(x['public_ip'])
      loop do
        global_ip = sprintf("%s.%s.%s.%s",gip[0],gip[1],gip[2],gip[3])
        # pingの応答が無いことをチェック
        if check_useable_ip(global_ip)
          if check_not_reserve_ip(global_ip)
            break
          end
        end
        gip[3] = gip[3] + 1        
      end
      x['public_ip'] = global_ip
      $vm_config_array[i] = x.to_s      
    end
    i = i + 1
  end

  #list_node_ip()  
  #p $vm_config_array
  #exit!
end

##
## 存在チェックとオーバーライド
##   $conf['kube_apiserver_vip']
##   $conf['front_proxy_vip']
##
def overwrite_vip_ip()
  lip = []
  local_ip = nil

  if $conf['kube_apiserver_vip'].nil? == false and $conf['kube_apiserver_vip_correct'] != true
    lip = conv_strIP_to_numIP($conf['kube_apiserver_vip'])
    loop do
      local_ip = sprintf("%s.%s.%s.%s",lip[0],lip[1],lip[2],lip[3])
      if check_useable_ip(local_ip)
        if check_not_reserve_ip(local_ip)
          break
        end
      end
      lip[3] = lip[3] + 1
    end
    $conf['kube_apiserver_vip'] = local_ip
  end

  if $conf['front_proxy_vip'].nil? == false
    lip = conv_strIP_to_numIP($conf['front_proxy_vip'])
    loop do
      local_ip = sprintf("%s.%s.%s.%s",lip[0],lip[1],lip[2],lip[3])
      if check_useable_ip(local_ip)
        if check_not_reserve_ip(local_ip)
          break
        end
      end
      lip[3] = lip[3] + 1
    end
    $conf['front_proxy_vip'] = local_ip
  end
  
end
