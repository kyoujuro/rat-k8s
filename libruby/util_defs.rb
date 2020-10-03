# coding: utf-8
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
## IPアドレスの文字列を数字配列に変換する
##
def conv_strIP_to_numIP(ip)
  num_ip = []
  string_ip = ip.split(/\./)
  for i in 0..3
    num_ip[i] = string_ip[i].to_i
  end
  return num_ip 
end

##
## ホスト名とIPアドレスとリスト
##
def list_node_ip()

  printf("%-12s    %-12s   %-12s\n","HOSTNAME","LOCAL IP","GLOBAL IP")
  $vm_config_array.each do |val|
    x = eval(val)
    if x['public_ip'].nil?
      printf("%-12s    %-12s\n",x['name'],x['private_ip'])
    else
      printf("%-12s    %-12s   %-12s\n",x['name'],x['private_ip'],x['public_ip'])
    end
  end
  if !$conf['kube_apiserver_vip'].nil?
    printf("%s = %-12s\n",'kube_apiserver_vip',$conf['kube_apiserver_vip'])
  end
  if !$conf['front_proxy_vip'].nil?
    printf("%s = %-12s\n",'front_proxy_vip',$conf['front_proxy_vip'])
  end
  if !$conf['istio_gateway_vip'].nil?
    printf("%s = %-12s\n",'istio_gateway_vip',$conf['istio_gateway_vip'])
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
        # Private IPが設定されない場合 Public IPを利用
        if x['private_ip'].nil? == true
          w = x['public_ip']
        else
          w = x['private_ip']
        end
        
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


