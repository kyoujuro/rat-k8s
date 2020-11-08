#!/bin/bash

source vm-spec.dat

function create_node() {

    #
    if [ ! -d $image_pool ]; then
       mkdir -p $image_pool
    fi
    # Setup Vol
    vdev=/dev/nbd2
    virtual_disk=$image_pool/$1.qcow2    
    modprobe nbd max_part=8
    qemu-nbd --connect=$vdev $os_image
    echo $?
    fdisk -l $vdev
    echo $?
    mount ${vdev}p2 ./vol
    echo $?
    sleep 20
    
    # Permit Root Login
    sed -i 's/^#PermitRootLogin/PermitRootLogin/' ./vol/etc/ssh/sshd_config 
    
    # root sshkey
    rm -fr ./vol/root/.ssh
    mkdir ./vol/root/.ssh
    cp id_rsa ./vol/root/.ssh/
    cp id_rsa.pub ./vol/root/.ssh/
    cp id_rsa.pub ./vol/root/.ssh/authorized_keys
    chmod 0700 ./vol/root/.ssh
    chmod 0600 ./vol/root/.ssh/*

    # ubuntu sshkey
    rm -fr ./vol/home/ubuntu/.ssh
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
    qemu-nbd --disconnect $vdev

    # copy disk image
    cp $os_image $virtual_disk

    # Start vm
    virt-install --name $1 \
		 --memory $2 --vcpus $3 \
		 --os-variant ubuntu18.04 \
		 --network network=$network --network network=private \
		 --import \
		 --disk $virtual_disk \
		 --graphics none \
		 --noautoconsole
}

#
##
### Main 
##
#

# ssh key
rm -f id_rsa id_rsa.pub
ssh-keygen -t rsa -N '' -f id_rsa

i=0;
for host in ${hosts[@]}; do
    create_node ${host} ${memory[${i}]} ${vcpus[${i}]} ${ips[${i}]}
    sleep 10
    let i++
done

