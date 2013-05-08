class authfile {
    file { "/root/export.sh":
        content => "export OS_TENANT_NAME=${admin_tenant}
export OS_USERNAME=${admin_user}
export OS_PASSWORD=${admin_password}
export OS_AUTH_URL=${os_auth_url}
export OS_REGION_NAME=${keystone_region}
export SERVICE_TOKEN=${admin_token}
export SERVICE_ENDPOINT=${service_endpoint}",
        notify => Exec["source export.sh"],
    }

    exec { "source export.sh":
        command => "echo 'source /root/export.sh' >> /root/.bashrc; sh /root/export.sh",
        path => $command_path,
        refreshonly => true,
    }
}
