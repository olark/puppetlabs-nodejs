# Class: nodejs
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Usage:
#
class nodejs(
  $dev_package = false,
  $proxy       = '',
  $use_legacy = true,
  $version = nil,
  $npm_version = nil,
  $dev_version = nil
) inherits nodejs::params {

  case $::operatingsystem {
    'Debian': {
      include 'apt'

      apt::source { 'sid':
        location    => 'http://ftp.us.debian.org/debian/',
        release     => 'sid',
        repos       => 'main',
        pin         => 100,
        include_src => false,
        before      => Anchor['nodejs::repo'],
      }

    }

    'Ubuntu': {
      include 'apt'
      if $use_legacy {
        # Always use PPA b/c it's up to date
        apt::ppa { 'ppa:chris-lea/node.js-legacy':
          before => Anchor['nodejs::repo'],
        }
      } else {
        apt::ppa { 'ppa:chris-lea/node.js':
          before => Anchor['nodejs::repo'],
        }
      }
    }

    'Fedora', 'RedHat', 'CentOS', 'OEL', 'OracleLinux', 'Amazon': {
      package { 'nodejs-stable-release':
        ensure => absent,
        before => Yumrepo['nodejs-stable'],
      }

      yumrepo { 'nodejs-stable':
        descr    => 'Stable releases of Node.js',
        baseurl  => $nodejs::params::baseurl,
        enabled  => 1,
        gpgcheck => $nodejs::params::gpgcheck,
        gpgkey   => 'http://patches.fedorapeople.org/oldnode/stable/RPM-GPG-KEY-tchol',
        before   => Anchor['nodejs::repo'],
      }
    }

    default: {
      fail("Class nodejs does not support ${::operatingsystem}")
    }
  }

  # anchor resource provides a consistent dependency for prereq.
  anchor { 'nodejs::repo': }

  if $version {
    package { 'nodejs':
      name    => $nodejs::params::node_pkg,
      ensure  => $version,
      require => Anchor['nodejs::repo']
    }
  } else {
    package { 'nodejs':
      name    => $nodejs::params::node_pkg,
      ensure  => present,
      require => Anchor['nodejs::repo']
    }
  }

  if $npm_version{
    package { 'npm':
      name    => $nodejs::params::npm_pkg,
      ensure  => $npm_version,
      require => Anchor['nodejs::repo']
    }

  } else {
    package { 'npm':
      name    => $nodejs::params::npm_pkg,
      ensure  => present,
      require => Anchor['nodejs::repo']
    }
  }

  if $proxy {
    exec { 'npm_proxy':
      command => "npm config set proxy ${proxy}",
      path    => $::path,
      require => Package['npm'],
    }
  }

  if $dev_version{
    if $dev_package and $nodejs::params::dev_pkg {
      package { 'nodejs-dev':
        name    => $nodejs::params::dev_pkg,
        ensure  => $dev_version,
        require => Anchor['nodejs::repo']
      }
    }
  } else {
    if $dev_package and $nodejs::params::dev_pkg {
      package { 'nodejs-dev':
        name    => $nodejs::params::dev_pkg,
        ensure  => present,
        require => Anchor['nodejs::repo']
      }
    }
  }

}
