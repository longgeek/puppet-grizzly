class quantum_dhcp_agent {
    package { "quantum-dhcp-agent":
        ensure => installed,
        notify => File["/etc/quantum/dhcp_agent.ini"],
    }

    file { "/etc/quantum/dhcp_agent.ini":
        content => template("quantum_dhcp_agent/dhcp_agent.ini.erb"),
        owner => "root",
        group => "quantum",
        mode => 640,
        notify => Service["quantum-dhcp-agent"],
    }

    service { "quantum-dhcp-agent":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }

}
