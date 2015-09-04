# -*- mode: ruby -*-
# vi: set ft=ruby :

define ecs::container::pipeworked(
  String $directory,
  String $ethadapter,
  String $ip,
  Array[String] $disks,
  String $container_name = $name,
  String $hostname = $title,
  Array[String] $env = ['SS_GENCONFIG=1'],
  $cluster_ips = [],
  String $default_route,
  Integer $netmask
) {

  ecs::container { $title:
    directory => $directory,
    ethadapter => $ethadapter,
    ip => $ip,
    disks => $disks,
    container_name => $container_name,
    hostname => $hostname,
    env => $env + ["INTERFACE=${ethadapter}"],
    cluster_ips => $cluster_ips
  }

  exec {  "/usr/local/bin/pipework br1 -i ${ethadapter} ${container_name} ${ip}/${netmask}@${default_route}":
    require => Docker::Run[$container_name]
  }

}
