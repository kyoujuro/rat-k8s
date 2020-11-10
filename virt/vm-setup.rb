#!/usr/bin/ruby
# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
require 'mb_string'
require 'yaml'
require 'json'
require '../libruby/read_yaml.rb'
require '../libruby/util_defs.rb'

$config_yaml = nil


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

  bootnode_ip = nil
  ##
  ## コンフィグに従って仮想マシンを起動
  ##
  $vm_config_array.each do |val|
    x = eval(val)

    printf("\n\nVM %s setup in progress\n", x['name'])
    step_start("OS Setup")

    
    # Configure Bootnode
    if x['name'] == "bootnode"

      bootnode_ip = x['private_ip']
      puts bootnode_ip
      # git clone
      cmd = sprintf("ssh -i id_rsa ubuntu@%s \"git clone https://github.com/takara9/rat-k8s\"", bootnode_ip)
      puts cmd
      value = %x( #{cmd} )
      puts value

      # bundler for ruby
      cmd = sprintf("ssh -i id_rsa ubuntu@%s \"cd rat-k8s && bundler\"", bootnode_ip)
      puts cmd
      value = %x( #{cmd} )
      puts value

      # setup config
      config = $config_yaml.gsub(/^..\//,"")
      cmd = sprintf("ssh -i id_rsa ubuntu@%s \"cd rat-k8s && ./setup.rb -f %s\"", bootnode_ip,config)
      value = %x( #{cmd} )
      puts value

      # ansible 
      cmd = sprintf("ssh -i id_rsa root@%s \"cd /home/ubuntu/rat-k8s && ansible-playbook -i hosts_kvm  -l %s playbook/setup_linux.yaml\"", bootnode_ip,"bootnode")
      value = %x( #{cmd} )
      puts value
      
    end
    step_end(0)
    
  end
  
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] != "bootnode"

      
      printf("==== %s ====\n",x['name'])
      
      cmd = sprintf("ssh -i id_rsa ubuntu@%s \"scp -r rat-k8s %s:\"", bootnode_ip, x['name'])
      value = %x( #{cmd} )
      puts value

    end
  end

  # ansible 
  cmd = sprintf("ssh -i id_rsa root@%s \"cd /home/ubuntu/rat-k8s && ansible-playbook -i hosts_kvm  playbook/setup_linux.yaml\"", bootnode_ip,"bootnode")
  value = %x( #{cmd} )
  puts value
  
end
