
# Picasa
class profile::picasa ()
{
    include archive

    ensure_packages(['wine',  'winetricks'])

    exec { 'winetricks -q ie8':
      environment => 'WINEARCH=win32 WINEPREFIX=~/.google/picasa/3.0/',
      require     => Package['winetricks'],
    }->
    archive { '/tmp/picasa.exe':
      source => 'http://dl.google.com/picasa/picasa39-setup.exe',
    }->
    exec { 'wine /tmp/picasa39-setup /S /L':
      
    }

}

# Look at here for ideas:
# https://sites.google.com/site/bmaupinwiki/home/operating-systems/gnu-linux/ubuntuelementary/ubuntu-gsettings-dconf
class profile::gnome::backup {

    package { [ 'deja-dup', 'deja-dup-backend-s3' ]: ensure => latest }

    gnome::gsettings { "wmpref":
        user => "user",
        schema => "org.gnome.desktop.wm.preferences",
            key => "theme",
            value => "Ambiance",
        }

}

class profile::docker {

    class { '::docker':
        #version => 'latest',
        docker_users => [ $profile::owner::username ],
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

# Puppet dev environment
class profile::puppet::developer {

    ensure_packages(['libxslt-dev', 'libxml2-dev', 'ruby-dev', 'zlib1g-dev' ])

    package { [ 'puppet-syntax', 'puppet-lint' ]:
        provider => 'gem',
        ensure   => 'present',
    }

  #if profile::editors
  #vim::plugin { 'puppet':
  #  source => 'https://github.com/rodjek/vim-puppet.git',
  #  require => [ Vim::Plugin['tabular'], Vim::Plugin['snippets'] ],
  #}

}

# An error in ZFS package make it unable to start at boot
# if the system use systemd (the default choice in Vivid)
# this define get fixed until a fix arrive from PPA
define profile::zfs::tmpfix() {
    wget::fetch { $name:
        source      => "https://raw.githubusercontent.com/zfsonlinux/zfs/master/etc/systemd/system/${name}.in",
        destination => "/etc/systemd/system/${name}",
    }->
    exec { "set-variable-sysconfdir-in-${name}":
        command => "/bin/sed --in-place 's#@sysconfdir@#/etc#' /etc/systemd/system/${name}",
        onlyif  => "/bin/grep '@sysconfdir@' /etc/systemd/system/${name}",
    }->
    exec { "set-variable-sbindir-in-${name}":
        command => "/bin/sed --in-place 's#@sbindir@#/sbin#' /etc/systemd/system/${name}",
        onlyif  => "/bin/grep '@sbindir@' /etc/systemd/system/${name}",
    }
}

# Install ZFS ppa to use this wonderful filesystem in your Box
class profile::zfs {

    contain ::zfs

    if $lsbdistcodename == 'vivid' {

        profile::zfs::tmpfix { 'zed.service': }
        profile::zfs::tmpfix { 'zfs-import-cache.service': }
        profile::zfs::tmpfix { 'zfs-import-scan.service': }
        profile::zfs::tmpfix { 'zfs-mount.service': }
        profile::zfs::tmpfix { 'zfs-share.service': }
        profile::zfs::tmpfix { 'zfs.target': }

    }

}

define motd::usernote($content = '') {
  file { "/etc/update-motd.d/60-${name}":
    content  => $content,
  }
}

class bash(
    $aliases = {},
    $rc = {},
)
{
    validate_hash($aliases)
    validate_hash($rc)

    package { [ 'bash', 'bash-completion', 'command-not-found' ] :
        ensure => latest,
    }

    # Host autocomplete runs better if knownhosts has not hostnames hashed
    wget::fetch { 'ssh-bash-autocomplete':
        source => 'http://cdn2.static.surniaulula.com/wp-content/uploads/crayon/complete-hosts.sh',
        destination => '/etc/profile.d/complete-hosts.sh',
    }


    file { '/etc/profile.d/load-puppet-profile.sh':
        content => "# file generated by puppet\n[ -f ~/.bashrc.puppet ] && source ~/.bashrc.puppet\n",
    }

    if $aliases {
        create_resources('bash::alias', $aliases)
    }

    if $rc {
        create_resources('bash::rc', $rc)
    }


}


# if user specified add config to ~/.bashrc.puppet
# else add config to system-wide bashrc.puppet.sh
define bash::rc(
  $content = '',
  $user = undef,
) {
  validate_string($content)

  $real_content = $content ? {
    ''      => $name,
    default => "# $name\n$content",
  }

  if $user {
    validate_string($user)
    $real_target = "/home/$user/.bashrc.puppet"
    validate_absolute_path($real_target)
  } else {
    $real_target  = '/etc/profile.d/bashrc.puppet.sh'
  }

  if ! defined(Concat[$real_target]) {
    concat { $real_target : }
    concat::fragment { 'systemwide-bashrc-header':
      content => "# file generated by Puppet\n\n",
      target  => $real_target,
      order   => '00',
    }
  }

  concat::fragment { $name:
    target  => $real_target,
    content => "$real_content\n\n",
  }
}

define bash::alias(
    $cmd
)
{
    bash::rc{ $name:
        content => "alias ${name}=\"${cmd}\"",
    }

}

class profile::phpredis {
  # Redis server
  class { 'redis': }
  # required for php-redis package
  apt::ppa { 'ppa:ufirst/php' :
    require => File['/etc/php5/conf.d'],
  }

  # required for php-redis package
  file { '/etc/php5/conf.d':
    ensure => directory,
  }

  file { '/etc/php5/mods-available/redis.ini':
    target => '/etc/php5/conf.d/redis.ini',
    require => Package['php5-redis'],
  }

  file { '/etc/php5/cli/conf.d/20-redis.ini':
    target => '../../mods-available/redis.ini',
  }

  Package['php5-redis'] -> Apt::Ppa['ppa:ufirst/php']

}

# PHP development env
class profile::phpdev {

  include php
  Package['php5-dev'] -> Php::Extension <| |> -> Php::Config <| |>

  class {
    'php::cli':;
    'php::dev':;
    'php::pear':;
    'php::extension::curl':;
    'php::extension::redis':;
    'php::composer':;
    'php::phpunit':;
  }
  package {'php5-json':; }

  class { 'composer':
    require => Package ['php5-curl'],
  }
}

node generic_desktop {

 # General dns conf
  dnsmasq::conf { 'general-options':
    content => "no-negcache\nlog-queries\nlog-async=50\n",
  }

  # Dev Environment
  dnsmasq::conf { 'resolv-dev.it':
    content   => 'address=/dev.it/127.0.1.1',
  }
  motd::usernote { 'dnsmasq':
    content => "Domains *.dev.it points to localhost, use it for your dev environments",
  }

  # Security
  class { 'sudo':
    require	=> Package['ruby-hiera'],
  }
  sudo::conf { 'wheel-group':
    priority => 10,
    content  => "%wheel ALL=(ALL) NOPASSWD: ALL",
  }
  group { 'wheel':
    ensure => 'present',
  }
  wget::fetch { 'gedit-solarized-theme-dark':
    source      => 'https://raw.github.com/altercation/solarized/master/gedit/solarized-dark.xml',
    destination => '/usr/share/gtksourceview-3.0/styles/solarized-dark.xml',
    require     => Package['gedit'],
  }
  wget::fetch { 'gedit-solarized-theme-light':
    source      => 'https://raw.github.com/altercation/solarized/master/gedit/solarized-light.xml',
    destination => '/usr/share/gtksourceview-3.0/styles/solarized-light.xml',
    require     => Package['gedit'],
  }

}


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


define profile::vagrant::box(
  $source,
  $username = 'root',
){

  include ::profile::vagrant

  $home = $username ? {
    'root'  => '/root',
    default => "/home/${username}"
  }

  if ! defined(File['vagrant-home']) {
    file { 'vagrant-home':
      path   => "${home}/vagrant",
      owner  => $username,
      ensure => directory,
    }
  }

  vcsrepo { "${home}/vagrant/${name}":
    source   => $source,
    ensure   => present,
    provider => git,
    require  => Package['git'],
  }

  file { "${home}/vagrant/${name}":
    owner   => $username,
    recurse => true,
  }
}


class desktop::proxy(
  $proxy,
  $noproxy = '127.0.0.1,127.0.1.1,localhost,*.local',
){
  package{ 'polipo': ensure => latest }
  bash::rc { 'setup polipo as a system wide proxy':
    content => "export {http,https,ftp}_proxy='http://${proxy}'",
  }
  if $noproxy {
    bash::rc { 'proxy skip rules':
      content => "export https_no_proxy='${noproxy}'\nexport http_no_proxy='${noproxy}'"
    }
  }
}

node motokosony {

  file { "$unix_home/.xprofile" :
    content => "SYSRESOURCES=/etc/X11/Xresources\nUSRRESOURCES=\$HOME/.Xresources\n",
    owner    => $unix_user,
  }

  class { 'vim':
    user     => $unix_user,
    home_dir => $unix_home,
  }

  # Vim colorscheme - http://ethanschoonover.com/solarized
  vim::plugin { 'colors-solarized':
    source => 'https://github.com/altercation/vim-colors-solarized.git',
  }
  vim::plugin { 'colors-monokai':
    source => 'https://github.com/sickill/vim-monokai.git',
  }
  vim::plugin { 'colors-gruvbox':
    source => 'https://github.com/morhetz/gruvbox.git',
  }
  vim::rc { 'sane-text-files':
    content => "set fileformat=unix\nset encoding=utf-8",
  }
  vim::rc { 'set number': }
  vim::rc { 'set tabstop=2': }
  vim::rc { 'set shiftwidth=2': }
  vim::rc { 'set softtabstop=2': }
  vim::rc { 'set expandtab': }

  vim::rc { 'set pastetoggle=<F6>': }

  vim::rc { 'intuitive-split-positions':
    content => "set splitbelow\nset splitright",
  }

  vim::rc { 'silent! colorscheme solarized': }
  #vim::rc { 'silent! colorscheme monokai': }
  vim::rc { 'background-x-gui':
    content => "if has('gui_running')\n\tset background=light\nelse\n\tset background=dark\nendif",
  }
  # Vim plugin: syntastic
  vim::plugin { 'syntastic':
    source => 'https://github.com/scrooloose/syntastic.git',
  }
  vim::plugin { 'tabular':
    source => 'https://github.com/godlygeek/tabular.git',
  }
  vim::plugin { 'snippets':
    source => 'https://github.com/honza/vim-snippets.git',
  }
  vim::plugin { 'enhanced-status-line':
    source => 'https://github.com/millermedeiros/vim-statline.git',
  }

  vim::plugin { 'nerdtree-and-tabs-together':
    source => 'https://github.com/jistr/vim-nerdtree-tabs.git',
  }
  vim::rc { 'nerdtree-start-on-console':
    content => 'let g:nerdtree_tabs_open_on_console_startup=1',
  }

  vim::plugin { 'tasklist':
    source => 'https://github.com/superjudge/tasklist-pathogen.git',
  }

  #vim::plugin { 'rainbow-parenthesis':
  #  source => 'https://github.com/oblitum/rainbow.git',
  #}
  vim::rc { 'activate rainbow parenthesis globally':
    content => 'let g:rainbow_active = 1',
  }

  vagrant::box { 'hhvm':
    source   => 'https://github.com/javer/hhvm-vagrant-vm',
    username => $unix_user,
  }

  class { 'desktop::proxy':
    proxy => '127.0.0.1:8123',
  }
}

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

# General DEFAULTS
Exec { path => '/usr/bin:/usr/sbin/:/bin:/sbin' }

Wget::Fetch {
    cache_dir => '/var/cache/puppet-wget'
}

node default {
    hiera_include('classes', [ 'stdlib' ])
}
