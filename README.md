openstack_grizzly_puppet_ubuntu
===============================

用 Puppet 批量部署 OpenStack Grizzly 到 Ubuntu 12.04、Ubuntu 12.04.2 上

安装说明：


一. 需要准备环境：  
    
        1. ubuntu 12.04.2 干净的系统, 一块网卡，走管理网络，给 control、compute 节点安装系统,同时又是 puppet master.
        2. ubuntu 12.04.2 系统 ISO 
        3. 环境中控制节点用两块网卡:eth0 和 eth1， 规定 eth0 为管理网络, eth1 为公网网络. 
           计算节点用三块网卡:eth0、eth1、eth2，规定 eth0 为管理网络, eth1 为公网网络, eth2 为数据网络 

三. 安装步骤：
    
        1. 启动你的 ubuntu 12.04.2 干净系统
        2. 手工配置系统的 eth0 网卡 IP 地址, 填写网关
        3. 拷贝 ISO 到系统 /opt/ 中
        4. 拷贝 安装目录到系统 /opt/ 中
        5. cd /opt/openstack_grizzly_puppet_ubuntu
           sh install.sh


四. 成功执行完 install.sh 后需要注意：

        1. source /etc/profile
        2. 编辑 /opt/pre-nodes 写入你需要安装节点的 IP 地址和 hostname，IP 地址必须和本节点 eth0 所在同一网段,也就是管理网络, 
           主机名必须是 FQDN, 域名需和本机一致. 格式如下：
           #    IP           HOSTNAME
            172.16.0.20     control.local.com
            172.16.0.21     compute21.local.com
            172.16.0.22     compute22.local.com
        3. 修改 /etc/puppet/manifests/site.pp 配置文件,这个配置文件主要要来设置 OpenStack 管理节点和计算节点的配置信息、基本变量：
           site.pp 需要根据实际环境来修改，下面给出一个范例可以参考：
           控制节点： hostname control.local.com
                      eth0 172.16.0.20
                      eth1 192.168.8.20
                      nova-volume 服务使用了 'sdb1' 和 'sdc1' 两块磁盘做块存储
                      控制节点上同时安装了 swift_proxy 模块


           计算节点1： hostname compute21.local.com
                      eth0 172.16.0.21
                      eth1 192.168.8.21
                      计算节点上同时安装了 swift_storage 模块, swift_storage 需要 'sdb1'、'sdc1'、'sdd1'三个磁盘做 storage. 复制次数为 1

           计算节点2： hostname compute22.local.com
                      eth0 172.16.0.22
                      eth1 192.168.8.22
                      计算节点上同时安装了 swift_storage 模块, swift_storage 需要 'sdb1'、'sdc1'、'sdd1'三个磁盘做 storage. 复制次数为 1


           上面环境就是默认的 /etc/puppet/manifests/site.pp 参数
    
        4. 执行 autodeploy 后就可以启动节点来进行 PXE 安装操作系统。
        5. 等 control 安装完系统后在安装 compute 节点，可以查看所有节点上的 /var/log/syslog 日志文件
