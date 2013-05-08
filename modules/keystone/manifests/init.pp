class keystone {
    package { "keystone":
        ensure => installed,
        notify => File["/etc/keystone/keystone.conf"],
    }

    file { "/etc/keystone/keystone.conf":
            content => template("keystone/keystone.conf.erb"),
            owner => "keystone",
            group => "keystone",
            mode =>  644,
            notify => File["/etc/keystone/keystone.sh"],
    }

    file { "/etc/keystone/keystone.sh":
            content => template("keystone/keystone.sh.erb"),
            owner => "root",
            group => "root",
            mode => 755,
            notify => Service["keystone"],
    }
    
    service { "keystone":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        notify => Exec["keystone_db_sync"],
    }

    exec { "keystone_db_sync":
        command => "keystone-manage db_sync",
        path => $command_path,
        refreshonly => true,
        notify => Exec["keystone_import_date"],
        
    }

    exec { "keystone_import_date":
        command => "sh /etc/keystone/keystone.sh && sleep 20; touch /etc/keystone/.keystone_import_date",
        path => $command_path,
        creates => "/etc/keystone/.keystone_import_date",
    }
}
