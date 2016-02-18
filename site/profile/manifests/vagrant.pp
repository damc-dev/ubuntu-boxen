class profile::vagrant(
    $manage_repo  = false,
    $manage_shell = false,
    $boxes_domain = undef,
    $plugins      = {},
) {

    validate_bool($manage_repo)
    validate_bool($manage_shell)
    validate_hash($plugins)

    if $manage_repo {
        apt::source { 'wolfgang42-vagrant':
            comment  => 'This is an unofficial .deb repository for Vagrant, hosted by Wolfgang Faust.',
            location => 'http://vagrant-deb.linestarve.com/',
            release  => 'any',
            repos    => 'main',
            key      => {
                'id' => '2099F7A4',
            },
        }
    }

    package { 'vagrant':    ensure => latest }

    #package { 'virtualbox': ensure => latest }

    if $manage_shell {
        wget::fetch { 'vagrant-bash-completion':
            source      => 'https://github.com/kura/vagrant-bash-completion/raw/master/vagrant',
            destination => '/etc/bash_completion.d/vagrant',
        }

        bash::rc { 'alias vu="vagrant up"' : }
        bash::rc { 'alias vp="vagrant provision"' : }
        bash::rc { 'alias vs="vagrant suspend"' : }
    }
    if $boxes_domain {
        dnsmasq::conf { "resolve-${boxes_domain}":
            content  => 'address=/${boxes_domain}/127.0.1.1',
        }
    }

    $plugin_defaults = {
        ensure => present,
    }

    if $plugins {
        create_resources('profile::vagrant::plugin', $plugins, $plugin_defaults)
    }
}
