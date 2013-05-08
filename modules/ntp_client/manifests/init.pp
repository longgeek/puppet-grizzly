class ntp_client {
    package { ["ntp", "ntpdate"]:
        ensure => installed,
        notify => Exec["sed"],
    }
    
    exec { "sed":
        command => "sed -i 's/server ntp.ubuntu.com/server ${mysql_host}/g' /etc/ntp.conf; /etc/init.d/ntp stop; ntpdate ${mysql_host}",
        path => $command_path,
        refreshonly => true,
        notify => Service["ntp"],
    }

    service { "ntp":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
