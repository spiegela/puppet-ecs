# -*- mode: ruby -*-
# vi: set ft=ruby :

define ecs::container(
  String $directory,
  String $ethadapter,
  String $ip,
  Array[String] $disks,
  String $container_name = $name,
  String $hostname = $title,
  Array[String] $env = ['SS_GENCONFIG=1'],
  $cluster_ips = []
) {

  include 'ecs::host'

  $image_name = inline_template("<%= scope.lookupvar('ecs::host::image_name') %>")

  file { [ "${directory}",
           "${directory}/data",
           "${directory}/host",
           "${directory}/host/data",
           "${directory}/host/files",
           "${directory}/disks",
           "${directory}/disks/uuid-1",
           "${directory}/files",
           "${directory}/logs"
    ]:
    ensure => 'directory',
    owner => '444',
    group => '444',
    mode => '755'
  }

  host { $hostname:
    ip => $ip
  }

  file { "${directory}/host/files/seeds":
    content => template('ecs/seed.erb')
  }

  file { "${directory}/host/data/network.json":
    content => template('ecs/network.json.erb')
  }

  ecs::volume {$disks: directory => $directory}

  docker::run { $container_name:
    image      => $image_name,
    volumes    => [ "${directory}/disks:/disks:rw",
                    "${directory}/host:/host",
                    "${directory}/data:/data:rw",
                    "${directory}/logs:/var/log"
                  ],
    net        => 'host',
    env        => $env,
    require    => Docker::Image[$image_name]
  }

}
