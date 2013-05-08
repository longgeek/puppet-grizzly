class cinder {
    package { ["cinder-api", "cinder-common", "cinder-scheduler", "cinder-volume", "python-cinderclient", "iscsitarget", "open-iscsi", "iscsitarget-dkms"]:
        ensure => installed,
        notify => File["/etc/cinder/cinder.conf"],
    }

    file { "/etc/cinder/cinder.conf":
        content => template("cinder/cinder.conf.erb"),
        owner => "cinder",
        group => "cinder",
        mode => 644,
        notify => File["/etc/cinder/api-paste.ini"],
    }

    file { "/etc/cinder/api-paste.ini":
        content => template("cinder/api-paste.ini.erb"),
        owner => "cinder",
        group => "cinder",
        mode => 644,
        notify => File["/etc/cinder/create-cinder-volumes.py"],
    }

    file { "/etc/cinder/create-cinder-volumes.py":
        content => template("cinder/create-cinder-volumes.py.erb"),
        mode => 755,
        notify => Exec["create_volume"],
    }

    exec { "create_volume":
        command => "cinder-manage db sync; python /etc/cinder/create-cinder-volumes.py",
        path => $command_path,
        refreshonly => true,
        notify => Service["iscsitarget", "open-iscsi", "cinder-api", "cinder-scheduler", "cinder-volume"],
    }

    service { ["iscsitarget", "open-iscsi", "cinder-api", "cinder-scheduler", "cinder-volume"]:
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
