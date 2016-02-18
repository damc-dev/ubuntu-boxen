class profile::software(
  $ensure = present,
  $packages = [],
  $gems = [],
  $ppas = {},
  $repos = {},
  $manage_python = true,
){

  validate_re($ensure, '^(present|absent|latest)$')
  validate_array($packages)
  validate_hash($ppas)
  validate_hash($repos)
  validate_array($gems)
  validate_bool($manage_python)

  # default for the create_resources of this class
  $defaults = {
    ensure => $ensure,
  }

  # merge packages from hiera
  $hiera_packages = hiera_array('profile::software::packages',undef)
  $fin_packages = $hiera_packages ? {
    undef   => $packages,
    default => $hiera_packages,
  }

  if $fin_packages {
    ensure_packages([ $fin_packages ])
  }

  # merge ppas from hiera
  $hiera_ppas = hiera_hash('profile::software::ppas',undef)
  $fin_ppas = $hiera_ppas ? {
    undef   => $ppas,
    default => $hiera_ppas
  }
  if $fin_ppas {
    create_resources('profile::software::ppa', $fin_ppas, $defaults)
  }

  if $repos {
    create_resources('profile::software::repo', $repos)
  }

  # merge gems from hiera
  $hiera_gems = hiera_array('profile::software::gems',undef)
  $fin_gems = $hiera_gems ? {
    undef   => $gems,
    default => $hiera_gems,
  }

  if $fin_gems {

    # common requirements for ruby gems compilation
    ensure_packages(['libxslt-dev', 'libxml2-dev', 'zlib1g-dev' ])
    ensure_packages(['ruby', 'ruby-dev', 'ruby-libxml'])

    package { $fin_gems:
        ensure   => $ensure,
        provider => 'gem',
        # require  => [ Package['ruby'], Package['ruby-dev'] ],
    }
  }
  if $manage_python {
    # python module is hiera-compliant, nothing special needed here
    include python
  }

}
