define profile::software::ppa(
  $ensure  = latest,
  $packages = [],
)
{
    apt::ppa { "ppa:${name}": }

    validate_array($packages)

    if $packages {
        package { $packages:
            ensure  => $ensure,
            require => Apt::Ppa["ppa:${name}"],
        }
    }
}


