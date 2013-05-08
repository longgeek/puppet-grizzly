class ntp_server {
    package { "ntp":
        ensure => installed,
        notify => Exec["sed"],
    }
    
    exec { "sed":
        command => "sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\\nserver 127.127.1.0\\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf",
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
