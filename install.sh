##!/bin/bash

## 更新源，并安装 Cobbler 和 Puppet 基本软件包.
apt-get update || exit 0

## 一些基本的变量
MANAGE_INTERFACE='eth0'
MANAGE_NETWORK='172.16.0.0/16'
DATE_NETWORK='10.0.0.0/8'
PUBLIC_NETWORK='192.168.8.0/24'
PUBLIC_GATEWAY='192.168.8.1'
PUBLIC_DNS='8.8.8.8'
ROOT_PASSWD="111111"
IPADDR=$(ifconfig $MANAGE_INTERFACE | awk '/inet addr/ {print $2}' | awk -F: '{print $2}')
ROUTE=$(route -n | grep $MANAGE_INTERFACE | grep ^0.0.0.0 | awk '{print $2}')
CHECKHOSTNAME=$(hostname | awk -F. '{print $3}')
ZONENAME=$(hostname | awk -F . '{print $2"."$3}')
SUBNETZONE=$(echo $IPADDR | awk -F. '{print $1"."$2"."$3}')
SUBNET=$(echo $SUBNETZONE'.0')
NETMASK=$(ifconfig $MANAGE_INTERFACE | awk '/Mask/ {print $4}' | awk -F: '{print $2}')
LS_ISO=$(file /opt/*.iso | grep 'Ubuntu-Server 1[2,3]' | head -n1)
ISO_NAME=$(echo $LS_ISO | awk -F: '{print $1}')
ISO_TYPE=$(echo $LS_ISO | awk -F"'" '{print $2}' | awk '{print $1"-"$2}')

## 判断 IP 地址是否设置; 主机名是否为 FQDN; /opt/下是否存在 ISO 文件; 是否有网关.
if [ "$IPADDR" = "" -o "$ZONENAME" = "." -o "$LS_ISO" = "" -o "$ROUTE" = "" -o "$CHECKHOSTNAME" = "" ]
then
    echo "\nERROR: 'Not set ip address!' or 'Hostname not FQDN!' or 'Iso not found!' or 'Not set gateway!'\n"
    exit 0
fi

apt-get -y --force-yes install cobbler cobbler-web isc-dhcp-server bind9 debmirror puppetmaster puppet || exit 0

## 修改 Cobbler 配置文件
COBBLER_PATH='/etc/cobbler/settings'
sed -i '/^manage_dhcp:.*$/ s/0/1/g' $COBBLER_PATH
sed -i '/^manage_dns:.*$/ s/0/1/g' $COBBLER_PATH
sed -i '/^manage_rsync:.*$/ s/0/1/g' $COBBLER_PATH
sed -i '/^manage_forward_zones:.*$/ s/\[\]/\["'$ZONENAME'"\]/g' $COBBLER_PATH
sed -i '/^manage_reverse_zones:.*$/ s/\[\]/\["'$SUBNETZONE'"\]/g' $COBBLER_PATH
sed -i "s/nobody.example.com/`hostname`/g" /etc/cobbler/zone.template
##sed -i '/^default_password_crypted:.*$/ s/""/"'$ROOT_PASSWD'"/g' $COBBLER_PATH
##sed -i '/^default_kickstart:.*$/ s/ubuntu-server/openstack/g' $COBBLER_PATH

## 修改 Cobbler 的 DHCP 模板文件
cat > /etc/cobbler/dhcp.template << _GEEK_
ddns-update-style interim;

allow booting;
allow bootp;

ignore client-updates;
set vendorclass = option vendor-class-identifier;

subnet $SUBNET netmask $NETMASK {
    default-lease-time         21600;
    max-lease-time             43200;
    #option ntp-servers  $IPADDR;    
}

group {
    include "/etc/dhcp/dhcpd-host.conf";
}
_GEEK_
touch /etc/dhcp/dhcpd-host.conf
cobbler sync

## 生成自动安装 Ubuntu 系统的 seed 文件
## openstack.preseed
echo "# Orchestra - Ubuntu Server Installation
# * Minimal install 
# * Cloud-init for bare-metal
# * Grab meta-data and user-data from cobbler server in a late command

# Locale 
d-i     debian-installer/locale string en_US.UTF-8

# No splash
d-i     debian-installer/splash boolean false

# Keyboard layout
d-i     console-setup/ask_detect        boolean false
d-i     console-setup/layoutcode        string us
d-i     console-setup/variantcode       string

# Network configuration
d-i     netcfg/get_nameservers  string
d-i     netcfg/get_ipaddress    string
d-i     netcfg/get_netmask      string $NETMASK
d-i     netcfg/get_gateway      string
d-i     netcfg/confirm_static   boolean true

# Local clock (set to UTC and use ntp)
d-i     clock-setup/utc boolean true
d-i     clock-setup/ntp boolean true
d-i     clock-setup/ntp-server  string
d-i     time/zone string Asia/Shanghai

d-i     partman-auto/disk string /dev/sda
d-i     partman-auto/method string regular
d-i     partman-lvm/device_remove_lvm boolean true
d-i     partman-md/device_remove_md boolean true
d-i     partman-lvm/confirm boolean true

# Part
d-i     partman-auto/expert_recipe string                         "\\"
          boot-root ::                                            "\\"
                  500 500 500 ext4                                "\\"
                          \$primary{ } \$bootable{ }                "\\"
                          method{ format } format{ }              "\\"
                          use_filesystem{ } filesystem{ ext4 }    "\\"
                          mountpoint{ /boot }                     "\\"
                  .                                               "\\"
                  1024 2048 200% linux-swap                       "\\"
                          method{ swap } format{ }                "\\"
                  .                                               "\\"
                  5120 10240 409600 ext4                          "\\"
                          method{ format } format{ }              "\\"
                          use_filesystem{ } filesystem{ ext4 }    "\\"
                          mountpoint{ / }                         "\\"
                  .     

d-i     partman/default_filesystem string ext4
d-i     partman-partitioning/confirm_write_new_label boolean true
d-i     partman/choose_partition select finish
d-i     partman/confirm boolean true
d-i     partman/confirm_nooverwrite boolean true
d-i     partman-md/confirm boolean true
d-i     partman-partitioning/confirm_write_new_label boolean true
d-i     partman/choose_partition select finish
d-i     partman/confirm boolean true
d-i     partman/confirm_nooverwrite boolean true
d-i     partman/mount_style select uuid

# Use server kernel
d-i     base-installer/kernel/image     string linux-server

# Account setup
d-i     passwd/root-login boolean root
d-i     passwd/root-password password $ROOT_PASSWD
d-i     passwd/root-password-again password $ROOT_PASSWD
d-i     user-setup/allow-password-weak boolean true
d-i     passwd/make-user boolean false
d-i     user-setup/encrypt-home boolean false
# This makes partman automatically partition without confirmation.
d-i     partman/confirm_write_new_label boolean true
d-i     partman/choose_partition        select Finish partitioning and write changes to disk
d-i     partman/confirm                 boolean true

# APT
d-i     mirror/country string manual
d-i     mirror/http/hostname string $IPADDR
d-i     apt-setup/security_host string $IPADDR
d-i     apt-setup/security_path string /cobbler/ks_mirror/$ISO_TYPE/
d-i     mirror/http/directory string /cobbler/ks_mirror/$ISO_TYPE/
d-i     mirror/http/proxy string

d-i     debian-installer/allow_unauthenticated string false

# Lang
d-i     pkgsel/language-packs   multiselect en
d-i     pkgsel/update-policy    select none
d-i     pkgsel/updatedb boolean true

# Boot-loader
d-i     grub-installer/skip     boolean false
d-i     lilo-installer/skip     boolean false
d-i     grub-installer/only_debian      boolean true
d-i     grub-installer/with_other_os    boolean false
d-i     finish-install/keep-consoles    boolean false
d-i     grub-installer/bootdev string /dev/sda
d-i     finish-install/reboot_in_progress       note

# Eject cdrom
d-i     cdrom-detect/eject      boolean true

# Do not halt/poweroff after install
d-i     debian-installer/exit/halt      boolean false
d-i     debian-installer/exit/poweroff  boolean false
d-i     pkgsel/include string  vim openssh-server ntp lvm2

# Set cloud-init data source to manual seeding
cloud-init      cloud-init/datasources  multiselect     NoCloud

d-i     preseed/late_command string true && cd /target; wget http://$IPADDR/post.sh; chmod +x ./post.sh; chroot ./ ./post.sh; true 
" > /var/lib/cobbler/kickstarts/openstack.preseed

## 挂在 ISO 镜像，并导入
umount $ISO_NAME
mount -o loop $ISO_NAME /mnt/
cobbler import --path=/mnt --name=$ISO_TYPE
cobbler distro edit --name=$ISO_TYPE-x86_64 \
--kernel=/var/www/cobbler/ks_mirror/$ISO_TYPE/install/netboot/ubuntu-installer/amd64/linux \
--initrd=/var/www/cobbler/ks_mirror/$ISO_TYPE/install/netboot/ubuntu-installer/amd64/initrd.gz \
--os-version=precise
cobbler profile edit --name=$ISO_TYPE-x86_64 \
--kopts="netcfg/choose_interface=auto " \
--kickstart=/var/lib/cobbler/kickstarts/openstack.preseed

-------------------------------------------------------- PUPPET --------------------------------------------------

## 配置 Puppet
mkdir /etc/puppet/files > /dev/null 2>&1
cat > /etc/puppet/autosign.conf << _GEEK_
`hostname`
*.$(hostname | awk -F. '{print $2"."$3}')
*.local
_GEEK_
/etc/init.d/puppetmaster restart
/etc/init.d/cobbler restart
cobbler sync
sleep 3
cobbler sync
sleep 3

## 在 dns 记录里加入本机记录
local_dns=$(cat /etc/bind/db.$SUBNETZONE | grep "`echo $IPADDR | awk -F. '{print $4}'`    IN    PTR    `hostname`.;")
if [ "$local_dns" = "" ]
then
    echo "`echo $IPADDR | awk -F. '{print $4}'`    IN    PTR    `hostname`.;" >> /etc/bind/db.$SUBNETZONE
    echo "`hostname | awk -F. '{print $1}'`    IN    A    $IPADDR;" >> /etc/bind/db.$ZONENAME
    /etc/init.d/bind9 restart
fi

## 下面内容会在 /var/www/ 下生成一个 post.sh 脚本，目的为了让 pxe 安装完的系统自动配置 eth0 eth1 eth2 的网卡 IP 地址.

echo "#!/bin/bash
cat > /etc/apt/sources.list << _GEEK_
deb http://`ifconfig $MANAGE_INTERFACE | grep 'inet addr:' | awk '{print $2}' | awk -F: '{print $2}'` grizzly/
_GEEK_
apt-get update
apt-get -y install ruby libshadow-ruby1.8 puppet facter --force-yes

#MANAGE_NETWORK=$MANAGE_NETWORK
#DATE_NETWORK=$DATE_NETWORK
#PUBLIC_NETWORK=$PUBLIC_NETWORK
#PUBLIC_GATEWAY=$PUBLIC_GATEWAY
#PUBLIC_DNS=$PUBLIC_DNS
eth0ipaddr=\$(ifconfig $MANAGE_INTERFACE | grep 'inet addr:' | awk '{print \$2}' | awk -F: '{print \$2}')
eth0ipaddrend=\$(echo \$eth0ipaddr | awk -F. '{print \$4}')
netnum=\$(ifconfig -a | grep 'eth[0,1,2,3]' | wc -l)
MANAGE_NETWORKS=\$(echo \$MANAGE_NETWORK | awk -F '.' '{print \$1\".\"\$2\".\"\$3}')
DATE_NETWORKS=\$(echo \$DATE_NETWORK | awk -F '.' '{print \$1\".\"\$2\".\"\$3}')
PUBLIC_NETWORKS=\$(echo \$PUBLIC_NETWORK | awk -F '.' '{print \$1\".\"\$2\".\"\$3}')
MANAGE_NETMASK=\$(echo \$MANAGE_NETWORK | awk -F '/' '{print \$2}')
DATE_NETMASK=\$(echo \$DATE_NETWORK | awk -F '/' '{print \$2}')
public_netmask=\$(echo \$PUBLIC_NETWORK | awk -F '/' '{print \$2}')

ifconfig $MANAGE_INTERFACE:0:0:0:0 10.232.189.34/\$MANAGE_NETMASK
MANAGE_NETMASKS=\$(ifconfig $MANAGE_INTERFACE:0:0:0:0 | awk '/Mask/ {print \$4}' | awk -F: '{print \$2}')
ifconfig $MANAGE_INTERFACE:0:0:0:0 10.232.189.34/\$DATE_NETMASK
DATE_NETMASKS=\$(ifconfig $MANAGE_INTERFACE:0:0:0:0 | awk '/Mask/ {print \$4}' | awk -F: '{print \$2}')
ifconfig $MANAGE_INTERFACE:0:0:0:0 10.232.189.34/\$DATE_NETMASK
PUBLIC_NETMASKS=\$(ifconfig $MANAGE_INTERFACE:0:0:0:0 | awk '/Mask/ {print \$4}' | awk -F: '{print \$2}')
ifconfig $MANAGE_INTERFACE:0:0:0:0 down

one () {
    cat > /etc/network/interfaces << _GEEK_
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address \$MANAGE_NETWORKS.\$eth0ipaddrend
    netmask \$MANAGE_NETMASKS
_GEEK_
}

two () {
    echo \"auto eth1
iface eth1 inet static
    address \$PUBLIC_NETWORKS.\$eth0ipaddrend
    netmask \$PUBLIC_NETMASKS
    gateway \$PUBLIC_GATEWAY
    dns-nameservers \$PUBLIC_DNS
\" >> /etc/network/interfaces
}

three () {
    echo \"auto eth2
iface eth2 inet static
    address \$DATE_NETWORKS.\$eth0ipaddrend
    netmask \$DATE_NETMASKS
\" >> /etc/network/interfaces

}

case \$netnum in
    0)
        echo 'Did not find the network card device!'
        exit 1
        ;;
    1)
        one
        ;;
    2)
        one
        two
        ;;
    *)
        one
        two
        three
        ;;
esac

sleep 5
apt-get -y install puppet
sleep 3
sed -i 's/no/yes/g' /etc/default/puppet
echo \"[main]
server=`hostname`
runinterval=5\" >> /etc/puppet/puppet.conf
echo \"\$eth0ipaddr \`hostname\`
`ifconfig $MANAGE_INTERFACE | grep 'inet addr:' | awk '{print $2}' | awk -F: '{print $2}'` `hostname`\" >> /etc/hosts
sed -i 's/-q -y/-q -y --force-yes/g' /usr/lib/ruby/1.8/puppet/provider/package/apt.rb" > /var/www/post.sh
