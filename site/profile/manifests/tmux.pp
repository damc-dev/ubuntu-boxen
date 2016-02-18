class profile::tmux {

  file { '/etc/tmux.conf':
    ensure => file,
    source => 'puppet:///modules/profile/tmux.conf',
    mode   => '644',
    owner  => 'root',
    group  => 'root',
    before => Package['tmux'],
  }

  package { 'tmux':
    ensure => 'latest'
  }


}
