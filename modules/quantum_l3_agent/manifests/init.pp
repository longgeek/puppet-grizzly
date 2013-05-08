class quantum_l3_agent {
    package { "quantum-l3-agent":
        ensure => installed,
        notify => File["/etc/quantum/l3_agent.ini"],
    }

    file { "/etc/quantum/l3_agent.ini":
        content => template("quantum_l3_agent/l3_agent.ini.erb"),
        owner => "root",
        group => "quantum",
        mode => 644,
        notify => Service["quantum-l3-agent"],
    }

    service { "quantum-l3-agent":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
