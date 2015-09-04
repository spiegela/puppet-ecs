# puppet-ecs

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with ECS](#setup)
    * [What ECS affects](#what-ecs-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with ecs](#beginning-with-ecs)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)

## Overview

This community created and maintained (therefore, not EMC supported) puppe
puppet library makes is possible to orchestrate
[ECS community edition](https://github.com/EMCECS/ECS-CommunityEdition)
containers with puppet.

Future goals of the project include the orchestration of ECS logical entities
including storage pools, virtual data centers, users, namespaces, etc.


## Setup

### What ECS affects

The module will change version of the Docker and SystemD services running on the
host to make them compatible with EMC ECS.  Docker-SE mode is disabled.  If
other services are running on the host, expect for them to be stopped.  If other
Docker containers are installed, expect for them to be removed.

The Docker [pipework](https://github.com/jpetazzo/pipework) script is installed
under `/usr/local/bin` despite the fact that it isn't working with ECS, yet.

ECS volumes are created for block devices specified in the manifest, and have an
XFS filesystem writted to them.

The ECS configuration files and Docker volumes are created under the `/ecs`
directory structure.

### Setup requirements

The ECS puppet module depends upon the
[Docker](https://forge.puppetlabs.com/garethr/docker),
[wait_for](https://forge.puppetlabs.com/basti1302/wait_for) and
[firewall](https://forge.puppetlabs.com/puppetlabs/firewall) modules.

### Beginning with ecs

To create an ECS docker container on the host, use the `ecs::container` type:

```puppet
ecs::container{ 'ecs-node1':
  directory => '/ecs/node1',
  ethadapter => 'ens33',
  hostname => 'node1',
  ip => '192.168.80.2',
  disks => ['sdb'],
  cluster_ips => ['192.168.80.2', '192.168.80.3']
}
```

The `sdb` device will be reformatted with XFS, and have ECS data files written
to it.  This will cause **all data on this device to be destroyed**, so be sure
you know what you're doing, please.

## Usage

If you want to start a cluster with just a single-node, you'll need to use
another defined variant: `ecs::container::single`.  This overrides ECS config
defaults, to bypass certain clustering checks.  Use it like you would the
standard container:

```puppet
ecs::container::single{ 'ecs-node1':
  directory => '/ecs/node1',
  ethadapter => 'ens33',
  hostname => 'node1',
  ip => '192.168.80.2',
  disks => ['sdb'],
  cluster_ips => ['192.168.80.2']
}
```

If you want to change the docker image used for the ECS container, you can
customize that like so:

```puppet
class { '::ecs::host':
  image_name => '<docker-user>/<some-other-docker-container>'
}
```

## Limitations

This module has only been tested on Centos-7 64-bit.  It will likely work fine
on other SystemD based Linux distributions.

There are currently pipework integration written in this module, but *they do
not work*.  I think this has to do with the Suse-based ECS docker image, and am
actively working on a work-around.  This means that only one container may be
run on a single host.
