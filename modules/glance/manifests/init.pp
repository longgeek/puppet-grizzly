class glance {
    package { "glance":
        ensure => installed,
        notify => File["/etc/glance/glance-api.conf", "/etc/glance/glance-registry.conf"],
    }

    file { "/etc/glance/glance-api.conf":
        content => template("glance/glance-api.conf.erb"),
        owner => "glance",
        group => "glance",
        mode => 644,
    }

    file { "/etc/glance/glance-registry.conf":
        content => template("glance/glance-registry.conf.erb"),
        owner => "glance",
        group => "glance",
        mode => 644,
        notify => Exec["glance_db_sync"],
    }

    exec { "glance_db_sync":
        command => "glance-manage version_control 0; \
                    glance-manage db_sync",
        path => $command_path,
        refreshonly => true,
        notify => Service["glance-api", "glance-registry"],
    }

    service { ["glance-api", "glance-registry"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        notify => File["/etc/glance/cirros-0.3.0-x86_64-disk.img"],
    }

    file { "/etc/glance/cirros-0.3.0-x86_64-disk.img":
        source => "puppet:///modules/glance/cirros-0.3.0-x86_64-disk.img",
        owner => "root",
        group => "root",
        mode => 644,
        notify => Exec["glance_add"],
    }

    exec { "glance_add":
        command => "glance --os_username=${admin_user} --os_password=${admin_password} --os_tenant_name=${admin_tenant} --os_auth_url=${os_auth_url} image-create --name='cirros-0.3.0' --public --container-format=ovf --disk-format=qcow2 < /etc/glance/cirros-0.3.0-x86_64-disk.img; touch /etc/glance/.glance_add",
        path => $command_path,
        creates => '/etc/glance/.glance_add'
    }
}
