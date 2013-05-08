class quantum_openvswitch_agent {
    package { "quantum-plugin-openvswitch-agent":
        ensure => installed,
        notify => File["/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini.sh"],
    }

    file { "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini.sh":
        content => template("quantum_openvswitch_agent/ovs_quantum_plugin.ini.sh.erb"),
        owner => "root",
        group => "root",
        mode => "755",
        notify => Exec["sh ovs_quantum_plugin.ini.sh"],
    }

    exec { "sh ovs_quantum_plugin.ini.sh":
        command => "sh /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini.sh",
        path => $command_path,
        refreshonly => true,
        notify => Service["quantum-plugin-openvswitch-agent"],
    }

    service { "quantum-plugin-openvswitch-agent":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
