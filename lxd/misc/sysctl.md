#LXD optimizations -- append to `/etc/sysctl.conf`

```
fs.aio-max-nr = 524288
fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_user_watches = 1048576
kernel.dmesg_restrict = 1
kernel.keys.maxbytes = 2000000
kernel.keys.maxkeys = 2000
#net.ipv4.neigh.default.gc_thresh3 = 8192
#net.ipv6.neigh.default.gc_thresh3 = 8192
vm.max_map_count = 262144
net.core.netdev_max_backlog = 182757
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.netdev_budget=5000
net.core.rmem_max=2500000
net.core.wmem_max=2500000
```
