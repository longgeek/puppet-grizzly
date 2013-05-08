class quantum_metadata_agent {
    package { "quantum-metadata-agent":
        ensure => installed,
        notify => File["/etc/quantum/metadata_agent.ini"],
    }

    file { "/etc/quantum/metadata_agent.ini":
        content => template("quantum_metadata_agent/metadata_agent.ini.erb"),
        owner => "root",
        group => "quantum",
        mode => 644,
        notify => Service["quantum-metadata-agent"],
    }

    service { "quantum-metadata-agent":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
