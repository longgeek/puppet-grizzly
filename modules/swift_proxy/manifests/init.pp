class swift_proxy {
    package { ["swift", "swift-proxy"]:
        ensure => installed,
        notify => Exec["/etc/swift"],
    }

    exec { "/etc/swift":
        command => "mkdir /etc/swift; chown -R swift:swift /etc/swift",
        path => $command_path,
        creates => "/etc/swift",
        notify => File["/etc/swift/swift.conf"],
    }

    file { "/etc/swift/swift.conf":
        content => template("swift_proxy/swift.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => 644,
        notify => File["/etc/swift/proxy-server.conf"],
    }

    file { "/etc/swift/proxy-server.conf":
        content => template("swift_proxy/proxy-server.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => 644,
        notify => File["/etc/swift/ring.py"],
    }

    file { "/etc/swift/ring.py":
        content => template("swift_proxy/ring.py.erb"),
        mode => 755,
        notify => Exec["python ring.py"],
    }

    exec { "python ring.py":
        command => "python /etc/swift/ring.py",
        path => $command_path,
        subscribe => File["/etc/swift/ring.py"],
        refreshonly => true,
        notify => Exec["create_ring & rsyslog"],
    }

    exec { "create_ring & rsyslog":
        command => "echo 'local0.*    /var/log/swift/proxy-server.log' >> /etc/rsyslog.conf; python /etc/swift/ring.py; chown -R swift:swift /etc/swift/; mkdir /var/log/swift; touch /etc/swift/.ring",
        path => $command_path,
        creates => "/etc/swift/.ring",
        notify => Service["rsyslog", "swift-proxy"],
    }

    service { ["rsyslog", "swift-proxy"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }

}
