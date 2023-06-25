#!/bin/bash
#
#x=$(lxc list -c n | awk '{ print $2}'  | sed -e '/^$/d' -e '/^NAME/d')
#A better way instead of using the sed and awk
#
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
