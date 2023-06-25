#!/bin/bash
#quick dirty swap with pre-built binary for cosmos chains
NEWBIN="https://autobuild.coldyvalidator.net/juno/pebbledb/junod-v15.0.0.tar.gz"
JUNOBIN=$(echo $(which junod))
systemctl stop junod && rm "$JUNOBIN"
wget -qO- $NEWBIN | tar xvz -C $(dirname $JUNOBIN)
systemctl start junod
