########OpenStack

node /^node\d+\.test\.com$/ {
    Class["ntp_server"] -> Class["mysql"] -> Class["rabbitmq"] -> Class["authfile"] -> Class["keystone"] -> Class["glance"] -> Class["openvswitch"] -> Class["quantum_server"] -> Class["quantum_metadata_agent"] -> Class["quantum_l3_agent"] -> Class["quantum_dhcp_agent"] -> Class["cinder"] -> Class["nova_control"] -> Class["horizon"]
	include ntp_server, mysql, rabbitmq, authfile, keystone, glance, openvswitch, quantum_server, quantum_metadata_agent, quantum_l3_agent, quantum_dhcp_agent, cinder, nova_control, horizon
	#include ntp_server, mysql, rabbitmq, authfile, keystone, glance, openvswitch, quantum_server, nova_control, horizon, quantum_metadata_agent, quantum_openvswitch_agent, quantum_l3_agent, quantum_dhcp_agent
}


node 'control.test.com' {
    Class["ntp_server"] -> Class["mysql"] -> Class["rabbitmq"] -> Class["authfile"] -> Class["keystone"] -> Class["glance"] -> Class["quantum_server"] -> Class["cinder"] -> Class["nova_control"] -> Class["horizon"] -> Class["swift_proxy"]
    include ntp_server, mysql, rabbitmq, authfile, keystone, glance, quantum_server, cinder, nova_control, horizon, swift_proxy
}

node 'compute1.test.com' {
    Class["ntp_client"] -> Class["openvswitch"] -> Class["quantum_client"] -> Class["quantum_openvswitch_agent"] -> Class["quantum_dhcp_agent"] -> Class["quantum_l3_agent"] -> Class["quantum_metadata_agent"] -> Class["nova_compute"] -> Class["swift_storage"]
    include ntp_client, openvswitch, quantum_client, quantum_openvswitch_agent, quantum_dhcp_agent, quantum_l3_agent, quantum_metadata_agent, nova_compute, swift_storage
}

##
#quantum_server 和 quantum_openvswitch_agent 冲突, 避免同时在一个节点上..
###

## Base ##
$debug_log                      = 'True'                            # 默认开启 debug 信息
$verbose                        = 'True'                            # 默认开启 verbose 信息
$command_path                   = '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/bin/bash'  # exec 资源的命令执行路径
$rabbit_host                    = '172.16.0.226'                    # rabbitmq 服务所在节点管理网络接口 IP 地址
$memcache_host                  = '172.16.0.226'

## Mysql ##
$mysql_host                     = '172.16.0.226'                    # mysql 服务所在节点的管理网络接口 IP 地址
$mysql_root_password            = 'mysql'                           # mysql root 用户的密码
$keystone_db_password           = 'keystone'                        # keystone 数据库的密码
$glance_db_password             = 'glance'                          # glance 数据库的密码
$cinder_db_password             = 'cinder'                          # cinder 数据库的密码
$quantum_db_password            = 'quantum'                         # quantum 数据库的密码
$nova_db_password               = 'nova'                            # nova 数据库的密码

## Keystone ##
$admin_user                     = 'admin'                           # 管理员用户名字
$admin_password                 = 'password'                        # 管理员用户密码
$admin_token                    = 'www.longgeek.com'                # keystone 的 token
$admin_tenant                   = 'admin'                           # 超级租户
$service_tenant_name            = 'service'                         # 所有服务所属的租户
$service_password               = 'password'                        # 所有服务用户的密码(keystone、glance、nova、quantum、cinder、swift)
$keystone_region                = 'RegionOne'
$service_endpoint               = 'http://172.16.0.226:35357/v2.0'  # endpoint
$os_auth_url                    = 'http://172.16.0.226:5000/v2.0'
$keystone_host                  = '172.16.0.226'                    # keystone 服务所在节点的管理网络接口 IP 地址

## Glance ##
$glance_host                    = '172.16.0.226'                    # glance 服务节点的管理网络接口 IP 地址
$glance_default_store           = 'file'                            # glance 镜像默认使用的存储类型, 默认为 file, 暂时不支持 swift。
$glance_workers                 = '1'                               # glance 服务节点的 CPU 核数

## Quantum ##
$br_ex_interfaces               = 'eth1'                            # br-ex 网桥使用哪个物理网卡
$br_ex_gateway                  = '192.168.8.1'                     # 外部网络接口的网关地址
$quantum_service_host           = '172.16.0.226'
$service_quantum_metadata_proxy = 'True'                            # 多网络节点、agent 时候开启为 True
$manage_network_interfaces      = 'eth0'                            # 管理网络接口
$external_network_interfaces    = $br_ex_interfaces                 # 外部网络接口
$data_network_interfaces        = 'eth0'                            # 数据网络接口, 主要用来 quantum openvswitch agent
$enable_multi_host              = 'True'
$use_namespaces                 = 'True'


## Nova ##
$nova_api                       = '172.16.0.226'
$novncproxy_base_url            = 'http://192.168.8.226:6080/vnc_auto.html'    # control nodes 外网 IP 地址

## Cinder ##
$cinder_volume_format           = "disk"                            # 默认为 'file', 用文件来模拟分区, 设置为 'file'是依赖 '$cinder_volume_size'
                                                                    # 设置为 'disk'时，依赖 '$cinder_volume_disk_part’
$cinder_volume_size             = "2G"                              # 使用 file 的话需要指定大小, 必须有单位
$cinder_volume_disk_part        = "['sdb1']"                        # 指定 cinder 使用哪些硬盘分区, 例如: "['sdb1', 'sdc1', 'sdd1']"


## Swift ##
$ring_part_power                = '18'
$ring_replicas                  = '1'                               # 每个对象文件副本数量 
$ring_min_part_hours            = '1' 
$swift_proxy_host               = '172.16.0.226'                    # swift-proxy 代理节点的管理网络接口 IP 地址
$proxy_workers                  = '2'                               # 代理节点 CPU 核数
$storage_workers                = '2'                               # 存储节点 CPU 核数
$storage_numbers                = '1'                               # 一共有几个存储节点 
$storage_nodes_ip               = '["172.16.0.227"]'                # 所有存储节点的 IP 地址，格式如: "['1.1.1.1', '1.1.1.2', '1.1.1.3']"
$storage_disk_part              = '["sdb1", "sdc1", "sdd1"]'        # 每个存储节点所使用的硬盘分区, 格式如: "['sdb1', 'sdc1', 'sdd3']"
$storage_base_dir               = '/swift-storage/node/'            # swift 存储目录
$swift_hash_suffix              = '50ea1ddb6e88b991'                # swift hash 值, 可以通过 # od -t x8 -N 8 -A n < /dev/random 这个命令来得出
