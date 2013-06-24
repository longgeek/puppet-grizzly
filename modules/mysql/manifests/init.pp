class mysql {

    file { "/etc/installmysql.py":
        content => template("mysql/installmysql.py.erb"),
        mode => 755,
        notify => Exec["python installmysql.py"],
    }

    exec { "python installmysql.py":
        command => "python /etc/installmysql.py",
        path => $command_path,
        creates => "/etc/.installmysql.txt",
        notify => Package["mysql-server", "python-mysqldb"],
    }
   
    package { ["mysql-server", "python-mysqldb"]:
        ensure => installed,
        notify => Exec["mysqlconf"],
    }


    exec { "mysqlconf":
        command => "sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf; sed -i '44 i skip-name-resolve' /etc/mysql/my.cnf; touch /etc/mysql/.mysqlconf",
        path => $command_path,
        notify => Exec["mysqldb"],
        creates => "/etc/mysql/.mysqlconf",
    }

    exec { "mysqldb":
        command => "mysql -uroot -p${mysql_root_password} -e \"create database keystone; \
                                                               create database glance; \
                                                               create database cinder; \
                                                               create database quantum; \
                                                               create database nova;\"; \
                    mysql -uroot -p${mysql_root_password} -e \"grant all on keystone.* to 'keystone'@'%' identified by '${keystone_db_password}'; \
                                                               grant all on glance.* to 'glance'@'%' identified by '${glance_db_password}'; \
                                                               grant all on cinder.* to 'cinder'@'%' identified by '${cinder_db_password}'; 
                                                               grant all on quantum.* to 'quantum'@'%' identified by '${quantum_db_password}';
                                                               grant all on nova.* to 'nova'@'%' identified by '${nova_db_password}';\"; \
                    touch /etc/mysql/.mysqldb",
        path => $command_path,
        notify => Service["mysql"],
        creates => "/etc/mysql/.mysqldb",
    }
    
    service { "mysql":
        ensure => running,
        enable => true,
        require => Exec["mysqldb"],
        hasstatus => true,
        hasrestart => true,
    }

}
