
class profile::docker {

    class { '::docker':
        #version => 'latest',
        docker_users => [ $profile::owner::username ],
        dns => '192.168.1.1',
    }

    # 25/8/2015 lorello
    # missing config for docker in systemctl
    # http://nknu.net/how-to-configure-docker-on-ubuntu-15-04/
    if $lsbdistrelease == '15.04' {
        file { '/etc/systemd/system/docker.service.d/ubuntu.conf':
            content => "[Service]\nEnvironmentFile=/etc/default/docker\nExecStart=\nExecStart=/usr/bin/docker -d -H fd:// \$DOCKER_OPTS\n",
        } ->
        exec { 'systemctl daemon-reload': }
        ->
        exec { 'systemctl restart docker': }
    }

}


