class swift_storage {
    package { ["swift", "swift-account", "swift-container", "swift-object", "xfsprogs", "rsync"]:
        ensure => installed,
        notify => File["/etc/swift/swift.conf"],
    }

    file { "/etc/swift/swift.conf":
        content => template("swift_storage/swift.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => "644",
        notify => File["/etc/swift/account-server.conf"],
        
    }

    file { "/etc/swift/account-server.conf":
        content => template("swift_storage/account-server.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => "644",
        notify => File["/etc/swift/container-server.conf"],
    }

    file { "/etc/swift/container-server.conf":
        content => template("swift_storage/container-server.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => "644",
        notify => File["/etc/swift/object-server.conf"],
    }

    file { "/etc/swift/object-server.conf":
        content => template("swift_storage/object-server.conf.erb"),
        owner => "swift",
        group => "swift",
        mode => "644",
        notify => File["/etc/rsyncd.conf"],
    }

    file { "/etc/rsyncd.conf":
        content => template("swift_storage/rsyncd.conf.erb"),
        mode => "644",
        notify => File["/etc/swift/ring_storage.py"],
    }

    file { "/etc/swift/ring_storage.py":
        content => template("swift_storage/ring_storage.py.erb"),
        mode => "755",
        notify => File["/etc/swift/disk_part.py"],
    }

    file { "/etc/swift/disk_part.py":
        content => template("swift_storage/disk_part.py.erb"),
        mode => "755",
        notify => Exec["sed_rsync & rsyslog"],
    }

    exec { "sed_rsync & rsyslog":
        command => "sed -i 's/=false/=true/g' /etc/default/rsync; echo -e \"
        local1.*    /var/log/swift/account.log
        local2.*    /var/log/swift/container.log
        local3.*    /var/log/swift/object.log\" >> /etc/rsyslog.conf; python /etc/swift/disk_part.py; python /etc/swift/ring_storage.py; touch /etc/swift/.disk_part",
        path => $command_path,
        creates => '/etc/swift/.disk_part',
        notify => Service["swift-account", "swift-container", "swift-object", "rsync", "rsyslog"],
    }

    service { ["swift-account", "swift-container", "swift-object", "rsync", "rsyslog"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
