
# yum install ruby rubygem-bundler

# 1 Download iso image

curl -O -L https://releases.ubuntu.com/18.04/ubuntu-18.04.5-live-server-amd64.iso


# 2 Start Virtual Machine Manager

---

File -> New Virtual Machine 
Check [Local install media (ISO image or CDROM)]
Click Forward

---

Choose ISO or CDROM install media:
[ubuntu-18.04.5-live-server-amd64.iso]
Click Forward

---

Memory: 2048
CPUs: 2

Click Forward

---

Check Enable storage for this virual machine

Select Create a disk image for the virtual machine
15 GiB

---

Ready to begin the installation

Name ubuntu18.04

Click Finish

---



# Install Ubuntu 18.04

Open QEMU/KVM Window

start Ubntu install process

---
select your language

English

---
Installer update available

Continue without updating

Choice [Continue without upating]
---

Keyboard configuration

Layout [ Japanese ]

[Done]
----

Network connections

[Done]
----
Configure proxy

[Done]
----
Confirure Ubnutu archive mirror

[Done]
---
Guided storage configuration
use default value

[Done]
---
Storage configuration
use default value

[Done]

for Confirm Window
[Continue]
---
Profile setup

Your name: Ubuntu
Your server's name:  ubuntu
Pick a username: ubuntu
Choose a password: ubuntu
Confirm your password: ubuntu
[Done]
----

SSH Setup

Check Install OpenSSH server
[Done]

----
Featured Server Snaps

no action
[Done]

----


Installation complete!

[Reboot]
---


# Setup Serail console

~~~
[tkr@yukikaze virt]$ sudo virsh 
virsh # list
 Id    Name                           State
----------------------------------------------------
 2     ubuntu18.04                    running

virsh # Ctrl-D
~~~


login from Virtual Machine Manager

~~~
sudo -s
password for ubuntu: ubuntu

vi /etc/default/grub
~~~



~~~file:/etc/default/grub
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.
# For full documentation of the options in this file, see:
#   info -f grub -n 'Simple configuration'

GRUB_DEFAULT=0
#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"

# Uncomment to enable BadRAM filtering, modify to suit your needs
# This works with Linux (no patch required) and with any kernel that obtains
# the memory map information from GRUB (GNU Mach, kernel of FreeBSD ...)
#GRUB_BADRAM="0x01234567,0xfefefefe,0x89abcdef,0xefefefef"

# Uncomment to disable graphical terminal (grub-pc only)
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"

# The resolution used on graphical terminal
# note that you can use only modes which your graphic card supports via VBE
# you can see them in real GRUB with the command `vbeinfo'
#GRUB_GFXMODE=640x480

# Uncomment if you don't want GRUB to pass "root=UUID=xxx" parameter to Linux
#GRUB_DISABLE_LINUX_UUID=true

# Uncomment to disable generation of recovery mode menu entries
#GRUB_DISABLE_RECOVERY="true"

# Uncomment to get a beep at grub start
#GRUB_INIT_TUNE="480 440 1"
~~~

apply changed file

~~~
# grub-mkconfig -o /boot/grub/grub.cfg
# reboot
~~~


# Confirm serial login

~~~
[tkr@yukikaze virt]$ sudo virsh 
virsh # list
 Id    Name                           State
----------------------------------------------------
 2     ubuntu18.04                    running

virsh # Ctrl-D
~~~

if appear ubuntu login then successfuly done

~~~
[tkr@yukikaze virt]$ sudo virsh console 2
Connected to domain ubuntu18.04
Escape character is ^]

Ubuntu 18.04.5 LTS ubuntu ttyS0

ubuntu login: 
~~~


## Start VM

list stopped VM

~~~
virsh # list --all
 Id    Name                           State
----------------------------------------------------
 -     ubuntu18.04                    shut off
Ctrl-D
~~~

start VM

~~~
[tkr@yukikaze virt]$ sudo virsh start ubuntu18.04 --console
Ubuntu 18.04.5 LTS ubuntu ttyS0

ubuntu login: 
Ctrl-]
~~~


# Copy virtual DISK

[tkr@yukikaze virt]$ sudo -s
[root@yukikaze virt]# cp /var/lib/libvirt/images/ubuntu18.04.qcow2 .

