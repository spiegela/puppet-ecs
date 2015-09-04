# -*- mode: ruby -*-
# vi: set ft=ruby :

define ecs::container::single(
  String $directory,
  String $ethadapter,
  String $ip,
  Array[String] $disks,
  String $container_name = $name,
  String $hostname = $title,
  Array[String] $env = ['SS_GENCONFIG=1'],
  $cluster_ips = []
) {

  include 'wait_for'

  ecs::container { $title:
    directory => $directory,
    ethadapter => $ethadapter,
    ip => $ip,
    disks => $disks,
    container_name => $container_name,
    hostname => $hostname,
    cluster_ips => $cluster_ips
  }

  wait_for { "${container_name}-running":
    query => '/bin/docker ps',
    regex => ".* ${container_name}"
  }

  exec { 'grab-object-props':
    command => "/bin/docker exec ${container_name} cp /opt/storageos/conf/cm.object.properties /host/cm.object.properties1",
    creates => "${directory}/host/cm.object.properties1",
    require => Wait_for["${container_name}-running"]
  }

  exec { 'grab-application-conf':
    command => "/bin/docker exec ${container_name} cp /opt/storageos/ecsportal/conf/application.conf /host/application.conf",
    creates => "${directory}/host/application.conf",
    require => Wait_for["${container_name}-running"]
  }

  exec { 'modify-object-props':
    command => "/usr/bin/sed s/object.MustHaveEnoughResources=true/object.MustHaveEnoughResources=false/ < ${directory}/host/cm.object.properties1 > ${directory}/host/cm.object.properties",
    creates => "${directory}/host/cm.object.properties",
    require => Exec['grab-object-props']
  }

  exec { 'modify-application-conf':
    command => "/usr/bin/echo ecs.minimum.node.requirement=1 >> ${directory}/host/application.conf",
    require => Exec['grab-application-conf']
  }

  exec { 'inject-object-props':
    command => "/bin/docker exec ${container_name} cp /host/cm.object.properties /opt/storageos/conf/cm.object.properties",
    require => Exec['modify-object-props']
  }

  exec { 'inject-application-conf':
    command => "/bin/docker exec ${container_name} cp /host/application.conf /opt/storageos/ecsportal/conf/application.conf",
    require => Exec['modify-application-conf']
  }

  exec { 'restart-ecs-container':
    command => "/bin/docker restart ${container_name}",
    require => [Exec['inject-object-props'], Exec['inject-application-conf']]
  }

}
