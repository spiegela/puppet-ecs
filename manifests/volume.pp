# -*- mode: ruby -*-
# vi: set ft=ruby :

define ecs::volume(
  String $directory,
  Integer $index = 0,
  String $disk = $title
) {
  if is_array($disk) {

    $length = inline_template('<%= $disk.length %>')
    $ulength = inline_template('<%= $disk.uniq.length %>')
    if ( "${length}" != '0' ) and ( "${length}" != "${ulength}" ) {
        fail('Array must not have duplicates.')
    }
    $index = inline_template('<%= $disk.index($name) %>')

    ecs::volume{ "${disk}": index => "${index}" }

  } else {

    exec { "create ${disk} partition-table":
      command => "/sbin/parted /dev/${disk} mklabel msdos",
      returns => [0, 1]
    }

    exec { "create ${disk}1 partition":
      command => "/sbin/parted /dev/${disk} mkpart primary 512 100%",
      creates => "/dev/${disk}1",
      require => Exec["create ${disk} partition-table"]
    }

    exec { "apply fs to ${disk}1":
      command => "/sbin/mkfs.xfs -f /dev/${disk}1",
      returns => [0, 1],
      require => Exec["create ${disk}1 partition"]
    }

    mount { "mount ${disk}1 to ${directory}/disks/uuid-${index}":
      name   => "${directory}/disks/uuid-1",
      ensure => 'mounted',
      atboot => true,
      device => "/dev/${disk}1",
      fstype => 'xfs',
      require => Exec["apply fs to ${disk}1"]
    }

    exec { "data-file-prep for ${disk}1":
      command => "/bin/bash /ecs/data_file_prep.sh /dev/${disk}1",
      require => [ Mount["mount ${disk}1 to ${directory}/disks/uuid-${index}"],
                   File["data-file-prep-script"]
                 ]
    }

  }
}
