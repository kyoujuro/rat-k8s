#!/usr/bin/ruby
# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
require 'mb_string'
require 'yaml'
require 'json'
require 'fileutils'
require '../libruby/read_yaml.rb'
require '../libruby/util_defs.rb'

$config_yaml = nil


##
## sudoer
##  
##
def write_sudoers(path, admin_name)
  ofn = path + "/etc/sudoers.d/" + admin_name
  File.open(ofn, "w") do |w|
    w.write sprintf("Defaults:%s !requiretty\n", admin_name)
    w.write sprintf("%s ALL = (ALL) NOPASSWD:ALL\n", admin_name)
  end
  FileUtils.chown_R("root","root", ofn)
  FileUtils.chmod(0440, ofn)
end

##
## Ubuntu netplan の設定ファイル作成
## 
##
def create_netplan_from_config(vm_name)
  $vm_config_array.each do |val|
    x = eval(val)
    if x['name'] == vm_name
      ofn = "01-netcfg.yaml"
      File.open(ofn, "w") do |w|
        w.write sprintf("network:\n")
        w.write sprintf("  version: 2\n")
        w.write sprintf("  renderer: networkd\n")
        w.write sprintf("  ethernets:\n")
        #w.write sprintf("    enp1s0:\n")
        #w.write sprintf("      dhcp4: true\n")
        if ! x['private_ip'].nil?
          #w.write sprintf("    enp2s0:\n")
          w.write sprintf("    enp1s0:\n")          
          w.write sprintf("      addresses:\n")
          w.write sprintf("      - %s\n", x['private_ip']+"/24")
        end
        if ! x['public_ip'].nil?
          #w.write sprintf("    enp3s0:\n")
          w.write sprintf("    enp2s0:\n")          
          w.write sprintf("      addresses:\n")
          w.write sprintf("      - %s\n", x['public_ip']+"/24")
          w.write sprintf("      gateway4: 192.168.1.1\n")
          w.write sprintf("      nameservers:\n")
          w.write sprintf("        addresses:\n")
          w.write sprintf("        - 192.168.1.1\n")
        else
          #w.write sprintf("    enp3s0:\n")
          w.write sprintf("    enp2s0:\n")          
          w.write sprintf("      dhcp4: true\n")
        end
      end
    end
  end
end


##
## OSイメージのカスタマイズ
##   ファイルの変更
##
def copy_ssh_to_vdisk(user_name,path)

  
  if user_name == "root"
    ssh_path = path + "/" + user_name + "/.ssh"
  else
    ssh_path = path + "/home/" + user_name + "/.ssh"
  end
  ssh_dir  = ssh_path + "/"

  FileUtils.rm_r(ssh_path, {:force => true})
  FileUtils.mkdir(ssh_path)
  FileUtils.cp("id_rsa", ssh_dir + "id_rsa")
  FileUtils.cp("id_rsa.pub", ssh_dir + "id_rsa.pub")
  FileUtils.cp("id_rsa.pub", ssh_dir + "authorized_keys")    
  FileUtils.chmod(0700, ssh_path)
  FileUtils.chmod(0600, ssh_dir + "authorized_keys")
  FileUtils.chmod(0600, ssh_dir + "id_rsa.pub")  
  if user_name == "root"
    FileUtils.chown_R("root","root", ssh_path)    
  else
    FileUtils.chown_R(1000,1000, ssh_path)
  end
end

##
## OSイメージのカスタマイズ
##   ファイルの変更
##
def setup_os_vdisk(path,vm_name)

  cmd = sprintf("sed -i 's/^#PermitRootLogin/PermitRootLogin/' %s/etc/ssh/sshd_config", path)
  puts %x( #{cmd} )
  File.write( path + "/etc/hostname", vm_name)
  
  FileUtils.remove_entry(path + "/etc/netplan")
  FileUtils.mkdir(path + "/etc/netplan")    
  FileUtils.cp("01-netcfg.yaml", path + "/etc/netplan/01-netcfg.yaml")
  
  copy_ssh_to_vdisk("root", path)
  copy_ssh_to_vdisk("ubuntu", path)  
end


##
## OSイメージのカスタマイズ
##   仮想ディスクのマウント
##
def configure_os_vdisk(vm_name)
    ## OSテンプレートのイメージをコピー
    step_start("OSイメージのコピー")
    cmd = sprintf("cp /home/images/%s /home/images/%s.qcow2","ubuntu18.04.qcow2", vm_name)
    value = %x( #{cmd} )
    puts value
    step_end(0)

    ## 仮想ストレージマウント
    nbd_dev = "/dev/nbd2"
    puts %x( modprobe nbd max_part=8 )
    cmd = sprintf("qemu-nbd --connect=%s /home/images/%s.qcow2",nbd_dev, vm_name)    
    puts %x( #{cmd} )
    cmd = sprintf("fdisk -l %s", nbd_dev)
    puts %x( #{cmd} )

    ## マウントポイントの作成
    cmd = sprintf("mkdir ./_%s", vm_name)
    %x( #{cmd} )

    ## 仮想ストレージのマウント
    path = sprintf("./_%s", vm_name)
    cmd = sprintf("mount %sp2 %s", nbd_dev, path)
    %x( #{cmd} )

    ##
    ## 仮想ディスクの設定変更
    ##
    setup_os_vdisk(path,vm_name)
    write_sudoers(path,"ubuntu")
    
    ## アンマウント
    cmd = sprintf("umount _%s", vm_name)    
    puts %x( #{cmd} )
    if $?.exitstatus == 0
      cmd = sprintf("rmdir _%s", vm_name)    
      puts %x( #{cmd} )
    end
      
    ## デバイスのデタッチ
    cmd = sprintf("qemu-nbd --disconnect %s",nbd_dev) 
    puts %x( #{cmd} )
    puts $?.exitstatus

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
  ## SSH鍵の生成
  ##
  step_start("SSH鍵の生成")  
  if File.exist?('id_rsa') and File.exist?('id_rsa.pub')
    puts '既存のSSH鍵を利用します'
  else
    puts %x( ssh-keygen -t rsa -N '' -f id_rsa)
  end
  step_end(0)
  
  ##
  ## 仮想マシンのストレージ作成
  ##
  step_start("仮想マシンのストレージ作成")    
  if File.directory?('/home/images') 
    puts '既存のイメージプールを利用します'
  else
    puts %x( mkdir /home/images)
  end
  step_end(0)


  
  ##
  ## コンフィグに従って仮想マシンを起動
  ##
  $vm_config_array.each do |val|
    x = eval(val)
    
    printf("\n\nVM %s の起動中\n", x['name'])
    create_netplan_from_config(x['name'])
    
    configure_os_vdisk(x['name'])
    
    ## OSテンプレートのイメージをコピー    
    step_start("仮想マシンの起動")
    cmd = "virt-install "
    cmd << sprintf(" --name %s", x['name'])
    cmd << sprintf(" --memory %s", x['memory'])
    cmd << sprintf(" --vcpus %s", x['cpu'])
    cmd << sprintf(" --os-variant %s", "ubuntu18.04")
    #cmd << sprintf(" --network network=%s --network network=%s --network network=%s", "default","private","public")
    cmd << sprintf("  --network network=%s --network network=%s", "private","public")    
    cmd << sprintf(" --import --graphics none --noautoconsole")
    cmd << sprintf(" --disk /home/images/%s.qcow2", x['name'])
    value = %x( #{cmd} )
    puts value
    step_end(0)
    
  end
end # END OF MAIN   
  
