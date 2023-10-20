#!/bin/sh

FLASH_TIME=$(opkg info busybox | grep '^Installed-Time: ')

for i in $(opkg list-installed | cut -d' ' -f1)
do
if [ "$(opkg info $i | grep '^Installed-Time: ')" != "$FLASH_TIME" ]
then
echo $i
fi
done
