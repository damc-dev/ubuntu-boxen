define profile::software::ppa(
  $ensure  = latest,
  $packages = [],
  $preinstall = undef,
)
{
    apt::ppa { "ppa:${name}": }

    validate_array($packages)

    if $packages {
        if $preinstall {
          exec { $preinstall:
            path => ["/usr/bin", "/usr/sbin"],
          }

          package { $packages:
            ensure  => $ensure,
            require => [ Apt::Ppa["ppa:${name}"], exec[$preinstall] ]
          }
        } else {
          package { $packages:
            ensure  => $ensure,
            require => Apt::Ppa["ppa:${name}"],
          }

        }

    }
}
