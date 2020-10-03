# coding: utf-8

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
  server_list_ingress_http = ""
  server_list_ingress_https = ""
  server_list_istio = ""
  server_list_istio_tls = ""
  
  $vm_config_array.each do |val|
    x = eval(val)
    ## ワーカーノード
    if x['name'] =~ /^node*/
      if x['role'] =~ /^worker/
        server_list_node = server_list_node + sprintf("%s server %s %s:30443 check\n", "\s"*4, x['name'], x['private_ip'])

        server_list_ingress_http = server_list_ingress_http + sprintf("%s server %s %s:31080 cookie %s check \n", "\s"*4, x['name'], x['private_ip'],x['name'])
        server_list_ingress_https = server_list_ingress_https + sprintf("%s server %s %s:31443 cookie %s check \n", "\s"*4, x['name'], x['private_ip'],x['name'])

        server_list_istio = server_list_istio + sprintf("%s server %s %s:31580 cookie %s check \n", "\s"*4, x['name'], x['private_ip'],x['name'])
        server_list_istio_tls = server_list_istio_tls + sprintf("%s server %s %s:31543 cookie %s check \n", "\s"*4, x['name'], x['private_ip'],x['name'])
        
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
        elsif line =~ /^__SERVER_LIST_INGRESS_HTTP__/
          w.write server_list_ingress_http
        elsif line =~ /^__SERVER_LIST_INGRESS_HTTPS__/
          w.write server_list_ingress_https
          break if $conf['istio_gateway_vip'].nil?
        elsif line =~ /^__SERVER_LIST_ISTIO__/
          w.write server_list_istio
        elsif line =~ /^__SERVER_LIST_ISTIO_TLS__/
          w.write server_list_istio_tls
        else
          w.write line
        end
      }
    end
  end
end

