class profile::owner(
  $username,
  $email,
  $groups,
) {
  user { $username:
    ensure => present,
    groups => $groups,
  }

  sudo::conf { $username:
    priority => 10,
    content  => "${username} ALL=(ALL) NOPASSWD: ALL",
  }

}


