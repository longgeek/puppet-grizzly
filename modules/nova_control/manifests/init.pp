class nova_control {
    package { ["nova-api", "nova-cert", "novnc", "nova-conductor", "nova-consoleauth", "nova-scheduler", "nova-novncproxy"]:
        ensure => installed,
        notify => File["/etc/nova/api-paste.ini"],
    }

    file { "/etc/nova/api-paste.ini":
        content => template("nova_control/api-paste.ini.erb"),
        owner => "nova",
        group => "nova",
        mode => 640,
        notify => File["/etc/nova/nova.conf.sh"],
    }

    file { "/etc/nova/nova.conf.sh":
        content => template("nova_control/nova.conf.sh.erb"),
        owner => "root",
        group => "root",
        mode => 755,
        notify => Exec["nova_db_sync"],
    }

    exec { "nova_db_sync":
        command => "sh /etc/nova/nova.conf.sh; nova-manage db sync",
        path => $command_path,
        refreshonly => true,
        notify => Service["nova-api", "nova-cert", "nova-consoleauth", "nova-scheduler", "nova-conductor", "nova-novncproxy"],
    }
    service { ["nova-api", "nova-cert", "nova-consoleauth", "nova-scheduler", "nova-conductor", "nova-novncproxy"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
