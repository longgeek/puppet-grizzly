class rabbitmq {
    package { "rabbitmq-server":
        ensure => installed,
        notify => Service["rabbitmq-server"],
    }

    service { "rabbitmq-server":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
