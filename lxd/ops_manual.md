# LXD quick-reference
[Official LXD Documentation](https://documentation.ubuntu.com/lxd/en/latest/)
<br>



## General config/complementary changes
[Full bash env files including aliases as shown](https://github.com/Cordtus/bitsnpcs/tree/65a39e97d18037e9b940acac68fc9f360b22b1e8/lxd/bash)

### `bash_aliases`

```
#use with network/container name (should be the same)
alias login="lxc-root"
alias log="lxc-daemon-log"
alias start="lxc-daemon-start"
alias doreboot="sudo lxc stop --all && sudo reboot"
alias listautostart="/usr/local/bin/lxc-autostart-settings.sh"
alias ram="lxc-ram"
alias clear-logs="lxc-logs"
alias doupdate="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias doupdate-r="doupdate && doreboot"
```

<br>

#### `definition of lxc-autostart-settings.sh`

```
#!/bin/bash
x=$(lxc list --format csv -c n)
echo 'The current values of each vm boot parameters:'
for c in $x
do
   echo "*** VM: $c ***"
   for v in boot.autostart boot.autostart.priority boot.autostart.delay 
   do
      echo "Key: $v => $(lxc config get $c $v)"
   done
      echo ""
done
```

### `lxc alias`
```
+---------+--------------------------------------------------------------------------------------------------------------------+
|  ALIAS  |                                                       TARGET                                                       |
+---------+--------------------------------------------------------------------------------------------------------------------+
| listall | list -c nst,image.os:os,4u,config:limits.cpu:cpu,D,devices:root.size:DISK_limit,m,config:limits.memory:mem_limit,M |
+---------+--------------------------------------------------------------------------------------------------------------------+
| login   | lxc-root                                                                                                           |
+---------+--------------------------------------------------------------------------------------------------------------------+
```
Some of the above will not work as `root` user. <br>

- `$ log <container name>` <br>
  executes `journalctl -u <daemon> -f -ocat` on host, given the container name is identical to the relevant systemd service name <br>
- `$ login <container name>` <br>
  gains shell access <br>
- `$ lxc listall` <br>
  prints ASCII table of containers and basic status/parameters <br>
- `$ listautostart` <br>
  prints `boot.autostart` values for all containers <br>

<br>

### managing instances
`$ lxc start <container>` <br>
`$ lxc stop <container>` <br>
`$ lxc restart <container>` <br>
`$ lxc rename <container> <newcontainer>` <br>
`$ lxc delete <container>` <br>


### creating instances - if no flags, configs as per default profile or instance being copied
`$ lxc launch images:<distro/version> <container> --storage <poolname> --profile <name>` <br>
`$ lxc copy <container> <newcontainer> --storage <poolname> --profile <name>` <br>




<br>

### per-container config [adjustable on-the-fly]

`$ lxc config set <container>	<key>				<value>`

```
<function>			<key>				<value>

*autostart*
start on boot			boot.autostart			<bool>
autostart order			boot.autostart.priority		<int>
initial delay			boot.autostart.delay		<int>
				
*memory*
mem limit			limits.memory			<1GB>
				
*cpu*
number of cores			limits.cpu			2
use cpu 1 only			limits.cpu 			0-0
use cpu 1-3			limits.cpu		 	0-2
10% usage/time			limits.cpu.allowance		10ms/100ms
```

<br>


### network limits

`$ lxc config device add <container> eth0 nic name=eth0 nictype=bridged parent=<lxdbr0>` <br>
`$ lxc config device set <container> eth0 limits.<ingress/egress> <1Mbit>`

### storage limits

#### `Add a root disk device per-container`

```
$ lxc config device add <container> root disk pool=<pool> path=/
$ lxc storage list
$ lxc config device set <container> root size 10GB
```

<br>

## LXD networking

**Important** - containers do not have their own firewall

Containers using NIC type 'bridged' with default 'lxdbr0' LXD bridge device for all containers share a subnet on the "virtual network"
containers sharing this network by default can communicate with eachother, the host machine and the LAN [assuming nat is enabled, per-container]

<br>

### `configure lxdbr0 bridgge device, add nat address/order, enable/disable ipv6 nat [to preference]`

`$ lxc network edit lxdbr0`

```
config:
  ipv4.address: 10.247.125.1/24
  ipv4.nat: "true"
  ipv4.nat.address: 209.250.238.45
  ipv4.nat.order: after
  ipv6.address: fd42:823d:9b4f:5418::1/64
  ipv6.nat: "false"
description: ""
name: lxdbr0
type: bridge
used_by:
- /1.0/instances/seid
- /1.0/instances/template
- /1.0/profiles/default
managed: true
status: Created
locations:
- none
```

### `configure NIC device per container for persistent private IP`
### `add IP/MAC filtering to prevent spoofing of other containers`

`$ lxc config edit <container>`

```
devices:
  eth0:
    ipv4.address: 10.247.125.xxx
    name: eth0
    nictype: bridged
    parent: lxdbr0
    security.ipv4_filtering: "true"
    security.ipv6_filtering: "true"
    security.mac_filtering: "true"
    type: nic
```

### `add basic UFW rules for LXD bridge device`

```
$ sudo ufw allow in on lxdbr0
$ sudo ufw route allow in on lxdbr0
$ sudo ufw route allow out on lxdbr0
```

<br>

### `incoming connections require a proxy device per-container`
#### forwards traffic from a custom port on host to relevant port on container

```
$ lxc config device add <container.name> <device.name> proxy connect=tcp:127.0.0.1:<internal port> listen=tcp:0.0.0.0:<host port>
$ sudo ufw allow <host port> && sudo ufw reload
```
