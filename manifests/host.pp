# -*- mode: ruby -*-
# vi: set ft=ruby :

class ecs::host($image_name = $ecs::config::image_name) inherits ecs::config {
  include 'docker'
  include 'firewall'

  package { 'systemd':
    ensure => '208-20.el7_1.5'
  }

  package { 'git':
    ensure => 'present'
  }

  package { 'tar':
    ensure => 'present'
  }

  package { 'wget':
    ensure => 'present'
  }

  exec { 'pipework-install':
    command => '/usr/bin/wget -q https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework -O /usr/local/bin/pipework',
    creates => '/usr/local/bin/pipework'
  }

  file { '/usr/local/bin/pipework':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '755'
  }

  exec { 'clear-docker-conf':
    command => '/bin/mv /etc/sysconfig/docker /etc/sysconfig/docker.orig',
    returns => [0, 1]
  }

  exec { 'docker-restart':
     command => '/bin/systemctl start docker',
     require => Exec['clear-docker-conf']
  }

  docker::image{ "${image_name}":
    require => Exec['docker-restart']
  }

  firewall { '000 allow ecs ports':
    port   => [64443, 4443, 9011, 9020, 9024, 443],
    proto  => tcp,
    action => accept
  }

  file { 'data-file-prep-script':
    ensure => 'file',
    source => 'puppet:///modules/ecs/data_file_prep.sh',
    path => '/ecs/data_file_prep.sh',
    mode  => '0755'
  }

  file { '/ecs':
    ensure => 'directory',
    owner => '444',
    group => '444',
    mode => '755'
  }

}
