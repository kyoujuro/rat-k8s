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
## 仮想マシンの削除
##
def destroy_vm(node)
  
  printf("\n\nVM %s の削除中\n", node['name'])
  step_start("OSの削除中")

  cmd = sprintf("virsh shutdown %s", node['name'])
  value = %x( #{cmd} )
  puts value

  cmd = sprintf("virsh domstate %s", node['name'])
  loop do
    value = %x( #{cmd} )
    if value.start_with?("shut off") or $?.exitstatus == 1
      break
    end
    sleep 1
  end
  
  cmd = sprintf("virsh undefine %s --remove-all-storage", node['name'])
  value = %x( #{cmd} )
  puts value

  step_end(0)
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

  ## Vagarntの仮想サーバースペックを作成
  ## 及び、メモリ編集に取り込み
  printf("ファイル名: %s\n",$config_yaml)
  step_start("コンフィグファイルの読み取り")
  vm_config = read_yaml_config($config_yaml)
  step_end( vm_config.length > 0 ? 0 : 1 )

  ##
  ## コンフィグに従って仮想マシンを起動
  ##
  $vm_config_array.each do |val|
    node = eval(val)
    if $target_host.nil?
      destroy_vm(node)
    else
      if $target_host == node['name']
        destroy_vm(node)
      end
    end
  end # END OF NODE    

end
