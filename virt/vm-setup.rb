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

$config_yaml = nil   # コンフィグファイル名
$target_host = nil   # 対象ホスト名


##
## GitクローンとLinux設定の反映
##
def setup_vm(node)

  printf("\n\nVM %s setup in progress\n", node)
  step_start("OS Setup")

  # git clone
  cmd = sprintf("ssh -i id_rsa ubuntu@%s \"git clone https://github.com/takara9/rat-k8s\"", node['private_ip'])
  value = %x( #{cmd} )
  puts value
    
  # bundler for ruby
  cmd = sprintf("ssh -i id_rsa ubuntu@%s \"cd rat-k8s && bundler\"", node['private_ip'])
  value = %x( #{cmd} )
  puts value
    
  # setup config
  config = $config_yaml.gsub(/^..\//,"")
  cmd = sprintf("ssh -i id_rsa ubuntu@%s \"cd rat-k8s && ./setup.rb -f %s\"", node['private_ip'],config)
  value = %x( #{cmd} )
  puts value
    
  # ansible 
  cmd = sprintf("ssh -i id_rsa root@%s \"cd /home/ubuntu/rat-k8s && ansible-playbook -i hosts_kvm  -l %s playbook/setup_linux.yaml\"", node['private_ip'],node['name'])
  value = %x( #{cmd} )
  puts value

  step_end(0)
end

##
##  Bootnodeの設定を他ノードへ展開する
##
def copy_config_from_bootnode_to_others()  

  bootnode_ip = nil
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] == "bootnode"
      bootnode_ip = x['private_ip']
    end
  end
  
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] != "bootnode"
      printf("==== %s ====\n",x['name'])
      cmd = sprintf("ssh -i id_rsa ubuntu@%s \"scp -r rat-k8s %s:\"", bootnode_ip, x['name'])
      puts cmd
      value = %x( #{cmd} )
      puts value
    end
  end
end


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
      if arg_state == "-n"
        $target_host = arg
      end
      arg_state = nil
    end
  end

  ##
  ## Vagarntの仮想サーバースペックを作成
  ## 及び、メモリ編集に取り込み
  ##
  printf("ファイル名: %s\n",$config_yaml)
  step_start("コンフィグファイルの読み取り")
  vm_config = read_yaml_config($config_yaml)
  step_end( vm_config.length > 0 ? 0 : 1 )

  ##
  ## コンフィグに従って仮想マシンを起動
  ##
  $vm_config_array.each do |val|
    node = eval(val)

    ## 対象ノードの指定が無い場合
    if $target_host.nil?
      if node['name'] == "bootnode"
        ## bootnodeでコンフィグ作成
        setup_vm(node)
        ## 構成結果を他ノードへコピー
        copy_config_from_bootnode_to_others()
        ## 一斉にAnsible Playbook を適用
        cmd = sprintf("ssh -i id_rsa root@%s \"cd /home/ubuntu/rat-k8s && ansible-playbook -i hosts_kvm  playbook/setup_linux.yaml\"", node['private_ip'])
        puts cmd
        value = %x( #{cmd} )
        puts value
      end
    else
      ## 対象ノードが指定された場合
      if $target_host == node['name']
        setup_vm(node)
        ## 対象ノード限定でAnsible Playbook を適用
        cmd = sprintf("ssh -i id_rsa root@%s \"cd /home/ubuntu/rat-k8s && ansible-playbook -i hosts_kvm -l %s playbook/setup_linux.yaml\"", node['private_ip'], node['name'])
        puts cmd
        value = %x( #{cmd} )
        puts value
      end
    end
  end # END OF NODE    
end # END OF MAIL
