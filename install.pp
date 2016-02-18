# Setup of uboxen
class { 'r10k':
  version => '1.3.2'
}

file { 
  '/usr/local/bin/uboxen':
    ensure => link,
    target => '/opt/ubuntu-boxen/uboxen';
  '/etc/puppet/manifests/site.pp':
    ensure => link,
    target => '/opt/ubuntu-boxen/uboxen.pp';
  '/etc/puppet/modules':
    ensure => link,
    target => '/opt/ubuntu-boxen/modules',
    force  => true;
  '/var/lib/hiera':
    ensure => link,
    target => '/opt/ubuntu-boxen/data';
  '/etc/puppet/hiera.yaml':
    ensure => link,
    target => '/opt/ubuntu-boxen/hiera.yaml';
  '/etc/hiera.yaml':
    ensure => link,
    target => '/opt/ubuntu-boxen/hiera.yaml';
}
