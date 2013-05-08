class quantum_client {
    package { "quantum-common":
        ensure => installed,
        notify => File["/etc/quantum/quantum.conf"],
    }

    file { "/etc/quantum/quantum.conf":
        content => template("quantum_server/quantum.conf.erb"),
        owner => "root",
        group => "quantum",
        mode => "644",
    }
}
