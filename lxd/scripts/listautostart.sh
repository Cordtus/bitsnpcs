#!/bin/bash

##prints full list of LXC container autostart values using alias 'listautostart'
#location '/usr/local/bin/lxc-autostart-settings.sh'

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
