
define profile::software::repo(
  $ensure = present,
  $location,
  $release = $::lsbdistcodename,
  $key = undef,
  $repos = 'main',
  $packages = [],
)
{

  validate_array($packages)

  apt::source { $name:
    ensure      => $ensure,
    location    => $location,
    release     => $release,
    key         => $key,
    repos       => $repos,
  }->
  package { $packages:
    ensure => $ensure,
  }

}



