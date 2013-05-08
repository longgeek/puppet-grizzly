class quantum_server {
    package { ["quantum-server", "quantum-plugin-openvswitch"]:
        ensure => installed,
        notify => File["/etc/quantum/quantum.conf"],
    }

    file { "/etc/quantum/quantum.conf":
        content => template("quantum_server/quantum.conf.erb"),
        owner => "root",
        group => "quantum",
        mode => "644",
        notify => File["/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"],
    }

    file { "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini":
        content => template("quantum_server/ovs_quantum_plugin.ini.erb"),
        owner => "root",
        group => "quantum",
        mode => "644",
        notify => Service["quantum-server"],
    }

    service { "quantum-server":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
