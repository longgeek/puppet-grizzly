class horizon {
    package { ["openstack-dashboard", "apache2", "memcached"]:
        ensure => installed,
        notify => File["/etc/openstack-dashboard/local_settings.py"],
    } 

    file { "/etc/openstack-dashboard/local_settings.py":
        content => template("horizon/local_settings.py.erb"),
        owner => "root",
        group => "root",
        mode => 644,
        notify => Exec["memcache_listen"],
    }

    exec { "memcache_listen":
        command => "sed -i 's/127.0.0.1/0.0.0.0/g' /etc/memcached.conf",
        path => $command_path,
        refreshonly => true,
        notify => Service["memcached", "apache2"],
    }

    service { ["memcached", "apache2"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
