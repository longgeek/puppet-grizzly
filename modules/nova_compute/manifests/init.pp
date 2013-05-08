class nova_compute {
    package { ["nova-compute", "nova-api-metadata"]:
        ensure => installed,
        notify => File["/etc/nova/api-paste.ini"],
    }

    file { "/etc/nova/api-paste.ini":
        content => template("nova_compute/api-paste.ini.erb"),
        owner => "nova",
        group => "nova",
        mode => 644,
        notify => File["/etc/nova/nova.conf.sh"],
    }

    file { "/etc/nova/nova.conf.sh":
        content => template("nova_compute/nova.conf.sh.erb"),
        owner => "root",
        group => "root",
        mode => 755,
        notify => Exec["nova-manage db sync"],
    }

    exec { "nova-manage db sync":
        command => "sh /etc/nova/nova.conf.sh; nova-manage db sync",
        path => $command_path,
        refreshonly => true,
        notify => Service["nova-compute", "nova-api-metadata"],
    }

    service { ["nova-compute", "nova-api-metadata"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
