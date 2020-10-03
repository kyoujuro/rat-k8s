#!/bin/bash

home_dir=/root/k8s-cluster
node_name=bootnode
os_disk_tmp=$home_dir/ubuntu.qcow2
network=k8s1
gateway=172.16.5.1
stg_pool=/home/qcow2s

hosts=("bootnode" "master1" "node1" "node2")
ips=("172.16.5.10" "172.16.5.21" "172.16.5.31" "172.16.5.32")
memory=(2048 2048 2048 2048)
vcpus=(2 2 2 2)


function import_node() {

    # Setup Vol
    virtual_disk=$stg_pool/$1.qcow2    
    modprobe nbd max_part=8
    qemu-nbd --connect=/dev/nbd1 $os_disk_tmp
    fdisk -l /dev/nbd1
    mount /dev/nbd1p1 ./vol

    # Permit Root Login
    sed -i 's/^#PermitRootLogin/PermitRootLogin/' ./vol/etc/ssh/sshd_config 
    
    # root sshkey
    mkdir ./vol/root/.ssh
    cp id_rsa ./vol/root/.ssh/
    cp id_rsa.pub ./vol/root/.ssh/
    cp id_rsa.pub ./vol/root/.ssh/authorized_keys
    chmod 0700 ./vol/root/.ssh
    chmod 0600 ./vol/root/.ssh/*

    # ubuntu sshkey
    mkdir ./vol/home/ubuntu/.ssh
    cp id_rsa ./vol/home/ubuntu/.ssh/
    cp id_rsa.pub ./vol/home/ubuntu/.ssh/
    cp id_rsa.pub ./vol/home/ubuntu/.ssh/authorized_keys
    chown -R 1000:1000 ./vol/home/ubuntu/.ssh
    chmod 0700 ./vol/home/ubuntu/.ssh
    chmod 0600 ./vol/home/ubuntu/.ssh/*
    
    # Set IP Address
    sed -e 's/999.999.999.999/'${4}'/' 01-netcfg.yaml > wk.yaml
    sed -e 's/888.888.888.888/'${gateway}'/' wk.yaml > wk2.yaml
    cat wk2.yaml
    cp wk2.yaml ./vol/etc/netplan/01-netcfg.yaml

    # Hostname
    echo $1 > ./vol/etc/hostname

    # Unmount
    umount vol
    qemu-nbd --disconnect /dev/nbd1

    # copy disk image
    cp $os_disk_tmp $virtual_disk

    # Start vm
    virt-install --name $1 \
		 --memory $2 --vcpus $3 \
		 --os-variant ubuntu18.04 \
		 --network network=$network \
		 --import \
		 --disk $virtual_disk \
		 --graphics none \
		 --noautoconsole
}

### Main

# ssh key
rm -f id_rsa id_rsa.pub
ssh-keygen -t rsa -N '' -f id_rsa



i=0;
for host in ${hosts[@]}; do
    import_node ${host} ${memory[${i}]} ${vcpus[${i}]} ${ips[${i}]}
    sleep 10
    let i++
done

