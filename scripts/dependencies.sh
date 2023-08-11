#! /bin/bash
#intended for a new bare debian system or vm/container
#installs most common cosmos SDK dependencies, some tools, sets PATH/GOPATH etc in bashrc
apt-get update > /dev/null && apt-get upgrade -y > /dev/null
apt-get install nano make build-essential gcc git jq chrony tar curl lz4 wget -y > /dev/null
if [ "$(which go)"  = '' ]
then
wget -q https://go.dev/dl/go1.20.linux-amd64.tar.gz > /dev/null
rm -rf /usr/local/go > /dev/null && tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz > /dev/null
rm go1.20.linux-amd64.tar.gz
fi
if [ "$GOROOT"  = '' ]
then
echo -e "export GOROOT=/usr/local/go\nexport GOPATH=$HOME/go\nexport GO111MODULE=on\nexport PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> .bashrc
source .bashrc
fi
