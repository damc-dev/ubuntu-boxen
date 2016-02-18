define profile::vagrant::plugin(
    $ensure = present,
) {

    if $ensure == 'present' {
        exec { "install-${name}":
            command => "/usr/bin/vagrant plugin install vagrant-${name}",
            unless  => "/usr/bin/sudo -u ${::profile::owner::username} /usr/bin/vagrant plugin list | grep vagrant-${name}",
            user    => $::profile::owner::username,
            environment => "HOME=/home/${::profile::owner::username}",
        }
    } else {
        exec { "uninstall-${name}":
            command => "/usr/bin/vagrant plugin uninstall vagrant-${name}",
            onlyif  => "/usr/bin/sudo -u ${::profile::owner::username} /usr/bin/vagrant plugin list | grep vagrant-${name}",
            user    => $::profile::owner::usernamett,
            environment => "HOME=/home/${::profile::owner::username}",
        }
    }
}



