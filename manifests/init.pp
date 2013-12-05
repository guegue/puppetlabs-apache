# Class: apache
#
# This class installs Apache
#
# Parameters:
#
# Actions:
#   - Install Apache
#   - Manage Apache service
#
# Requires:
#
# Sample Usage:
#
class apache (
  $default_mods = true,
  $service_enable = true,
  $serveradmin  = 'root@localhost',
  $sendfile     = false,
  $purge_vdir   = false,
) {
  include apache::params

  package { 'httpd':
    ensure => installed,
    name   => $apache::params::apache_name,
  }

  # true/false is sufficient for both ensure and enable
  validate_bool($service_enable)

  service { 'httpd':
    ensure    => $service_enable,
    name      => $apache::params::apache_name,
    enable    => $service_enable,
    subscribe => Package['httpd'],
  }

  file { 'httpd_vdir':
    ensure  => directory,
    path    => $apache::params::vdir,
    recurse => true,
    purge   => $purge_vdir,
    notify  => Service['httpd'],
    require => Package['httpd'],
  }

  if $apache::params::conf_dir and $apache::params::conf_file {
    # Template uses:
    # - $apache::params::user
    # - $apache::params::group
    # - $apache::params::conf_dir
    # - $serveradmin
    file { "${apache::params::conf_dir}/${apache::params::conf_file}":
      ensure  => present,
      content => template("apache/${apache::params::conf_file}.erb"),
      notify  => Service['httpd'],
      require => Package['httpd'],
    }
    if $default_mods == true {
      include apache::mod::default
    }
  }
  if $apache::params::mod_dir {
    file { $apache::params::mod_dir:
      ensure  => directory,
      require => Package['httpd'],
    } -> A2mod <| |>
    resources { 'a2mod':
      purge => true,
    }
  }

  # add essentials apache 2.4
  if $::operatingsystem == 'Fedora' and $::operatingsystemrelease >= 18 {
    file { '/etc/httpd/mod.d/00-mpm.load':
      ensure  => present,
      source => 'puppet:///modules/apache/00-mpm.load',
      notify => Service['httpd'],
    }
    file { '/etc/httpd/mod.d/00-systemd.load':
      ensure  => present,
      source => 'puppet:///modules/apache/00-systemd.load',
      notify => Service['httpd'],
    }
    file { '/etc/httpd/mod.d/00-base.load':
      ensure  => present,
      source => 'puppet:///modules/apache/00-base.load',
      notify => Service['httpd'],
    }
  }
}
