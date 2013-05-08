class openvswitch {
    package { ["openvswitch-brcompat", "openvswitch-switch"]:
        ensure => installed,
        notify => Exec["boot_brcompat"],
    }

    exec { "boot_brcompat":
        command => "sed -i 's/# BRCOMPAT=no/BRCOMPAT=yes/g' /etc/default/openvswitch-switch; /etc/init.d/openvswitch-switch force-reload-kmod; touch /etc/openvswitch/.boot_brcompat",
        path => $command_path,
        creates => "/etc/openvswitch/.boot_brcompat",
        notify => Service["openvswitch-switch"],
    }

    service { "openvswitch-switch":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        notify => File["/etc/openvswitch/create-bridge-network.sh"],
    }

    file { "/etc/openvswitch/create-bridge-network.sh":
        content => template("openvswitch/create-bridge-network.sh.erb"),
        owner => "root",
        group => "root",
        mode => "755",
        notify => Exec["sh_scripts"],
    }

    exec { "sh_scripts":
        command => "sh /etc/openvswitch/create-bridge-network.sh; sleep 20; touch /etc/openvswitch/.sh_scripts",
        path => $command_path,
        creates => "/etc/openvswitch/.sh_scripts",
    }
}
