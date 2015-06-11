class profile::puppetdev {
  
  # Puppet dev environment
  package { [ 'libxslt-dev', 'libxml2-dev']: ensure => present }
  package { 'nokogiri':
    ensure => '1.5.11',
    provider => 'gem',
    require => [ Package['libxslt-dev'], Package['libxml2-dev']],
  }
  package { [ 'ruby-dev', 'ruby-hiera' ] : ensure => present }
  package { [ 'puppet-lint', 'puppet-syntax', 'librarian-puppet', 'rspec-puppet', 'puppetlabs_spec_helper', 'r10k' ]:
    provider => 'gem',
    ensure   => 'present',
  }

  vim::plugin { 'puppet':
    source => 'https://github.com/rodjek/vim-puppet.git',
    require => [ Vim::Plugin['tabular'], Vim::Plugin['snippets'] ],
  }

}

define motd::usernote($content = '') {
  file { "/etc/update-motd.d/60-${name}":
    content  => $content,
  }
}

define git::config(
  $section='',
  $key='',
  $value,
  $user='')
{

  include git

  if empty($user)
  {
    $real_command = "git config --system"
  } else {
    validate_string($user)
    $real_command = "sudo -u ${user} git config --global"
  }

  if empty($section) and empty($key) {
    validate_re($name, '^\w+\.\w+$')
    $real_section_key = $name
  } else {
    $real_section_key = "${section}.${key}"
  }

  exec { $real_section_key:
    command => "${real_command} ${real_section_key} \"$value\"",
    unless  => "test \"`${real_command} ${real_section_key}`\" = \"${value}\"",
    require => Package['git'],
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

node generic_host {

  git::config { 'alias.up' :              value => 'pull origin' }
  git::config { 'core.sharedRepository':  value => 'group' }
  git::config { 'color.interactive':      value => 'auto' }
  git::config { 'color.showbranch':       value => 'auto' }
  git::config { 'color.status' :          value => 'auto' }


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


class vagrant {

    apt::source { 'wolfgang42-vagrant':
        comment  => 'This is an unofficial .deb repository for Vagrant, hosted by Wolfgang Faust.',
        location => 'http://vagrant-deb.linestarve.com/',
        release  => 'any',
        repos    => 'main',
        key      => {
            'id' => '2099F7A4',
        },
    }->
    package { 'vagrant':    ensure => latest }

    package { 'virtualbox': ensure => latest }

    wget::fetch { 'vagrant-bash-completion':
        source      => 'https://github.com/kura/vagrant-bash-completion/raw/master/vagrant',
        destination => '/etc/bash_completion.d/vagrant',
    }

    bash::rc { 'alias vu="vagrant up"' : }
    bash::rc { 'alias vp="vagrant provision"' : }
    bash::rc { 'alias vs="vagrant suspend"' : }

    dnsmasq::conf { 'resolve-vagrant.local':
        content  => 'address=/vagrant.local/127.0.1.1',
    }

}


define vagrant::box(
  $source,
  $username = 'root',
){

  include vagrant

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

  git::config { 'user.name' : user => $unix_user, value => $unix_user }
  git::config { 'user.email': user => $unix_user, value => $email }

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

class profile::git(
  $config,
) {
  create_resources('git::config', $config)
}


class profile::qualcosa(
){

  vagrant::box { 'hhvm':
    source   => 'https://github.com/javer/hhvm-vagrant-vm',
    username => $unix_user,
  }

  # picasa
  package { [ 'wine', 'winetricks']:  ensure => latest }


  class { 'desktop::proxy':
    proxy => '127.0.0.1:8123',
  }
}

class profile::git(
  $config,
) {
  create_resources('git::config', $config)
}


class profile::software(
  $ensure = present,
  $packages = [],
  $gems = [],
  $ppas = {},
  $repos = {},
){

  validate_re($ensure, '^(present|absent|latest)$')
  validate_array($packages)
  validate_hash($ppas)
  validate_hash($repos)
  validate_array($gems)

  $defaults = {
    ensure => $ensure,
  }

  if $packages {
    package { $packages: ensure => $ensure }
  }
  if $ppas {
    create_resources('profile::software::ppa', $ppas, $defaults)
  }
  if $repos {
    create_resources('profile::software::repo', $repos)
  }
  if $gems {
    package { $gems:
        ensure   => $ensure,
        provider => 'gem',
    }
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
            ensure => $ensure
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
#Exec { path => '/usr/bin:/usr/sbin/:/bin:/sbin' }

node default {
	hiera_include('classes', [ 'stdlib' ])
}

