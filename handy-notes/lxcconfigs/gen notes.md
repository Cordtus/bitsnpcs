#HOST FIREWALL RULES FOR OUTGOING -- LXC BRIDGE
ufw allow in on <lxdbr0>
ufw route allow in on <lxdbr0>

#PROXY FOR INCOMING TRAFFIC
lxc config device add <container> <proxy name> proxy listen=tcp:0.0.0.0:<external/host port> connect=tcp:127.0.0.1:<internal/container port>


#BETTER CONTAINERS LIST (lxc listall)
lxc alias add listall "list -c nst,image.os:os,4u,config:limits.cpu:cpu,D,devices:root.size:DISK_limit,m,config:limits.memory:mem_limit,M"


#AUTOSTART & LIMITS
lxc config set <container> 	<key> 				<value>

				boot.autostart 			true
				boot.autostart.priority 	<integer>
#post-start delay		boot.autostart.delay 		<integer>
				limits.memory 			<1GB>
#number of cores		limits.cpu 			2
#use cpu 1 only			limits.cpu 			0-0
#use cpu 1-3			limits.cpu 			0-2
#10% usage/time			limits.cpu.allowance 		10ms/100ms

#NETWORK LIMITS
lxc config device add <container> eth0 nic name=eth0 nictype=bridged parent=<lxdbr0>
lxc config device set <container> eth0 limits.<ingress/egress> <1Mbit>

#DISK LIMITS
#add a root disk device per-container
lxc config device add <container> root disk pool=<pool> path=/
lxc storage list
lxc config device set <container> root size 10GB
