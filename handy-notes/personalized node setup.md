# *Run each line one at a time unless otherwise directed*
**---------------------------------------------------------**

<br>

<br>

# Connect to server via SSH
## Create new user
`adduser node`

<br>

## Set permissions for new user
`usermod -aG sudo node`

<br>

## Switch to new user
`su -l node`

<br>

### NOTE - from now on when you connect to the server over SSH use this newly created user instead of 'root'

**---------------------------------------------------------**

<br>

## Update packages
`sudo apt update && sudo apt upgrade -y`

<br>

## Configure UFW
`sudo ufw default deny incoming`

`sudo ufw default allow outgoing`

`sudo ufw allow ssh`

`sudo ufw allow 26656`

`sudo ufw enable && sudo ufw reload`

<br>

## Install dependencies
`sudo apt install nano make build-essential pkg-config libssl-dev git libleveldb-dev gcc git jq chrony tar curl lz4 wget -y`

`wget -q https://go.dev/dl/go1.19.linux-amd64.tar.gz`

`sudo tar -C /usr/local -xzf go1.19.linux-amd64.tar.gz`

`rm go1.19.linux-amd64.tar.gz`

<br>

## Configure PATH, GOPATH etc. [Copy and paste the following lines together]
```
if [ "$GOROOT"  = '' ]
then
echo -e "export GOROOT=/usr/local/go\nexport GOPATH=$HOME/go\nexport GO111MODULE=on\nexport PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
source ~/.bashrc
fi
```

<br>

## Confirm go install/config
`go version`
#### [should return 'go version go1.19 linux/amd64']


<br>

## Install chain binary
`cd ~/`

`git clone https://github.com/ArableProtocol/acrechain && cd acrechain`

`git checkout v1.1.1`

`make install`

<br>

## Initialize node
`acred init temp --chain-id acre_9052-1`

<br>

## Add genesis file
```
wget https://raw.githubusercontent.com/ArableProtocol/acrechain/main/networks/mainnet/acre_9052-1/genesis.json -O ~/.acred/config/genesis.json
```

<br>

## Add peers to config file [copy+paste the following lines together]
```
cd

PEERS="ef28f065e24d60df275b06ae9f7fed8ba0823448@46.4.81.204:34656,e29de0ba5c6eb3cc813211887af4e92a71c54204@65.108.1.225:46656,276be584b4a8a3fd9c3ee1e09b7a447a60b201a4@116.203.29.162:26656,e2d029c95a3476a23bad36f98b316b6d04b26001@49.12.33.189:36656,1264ee73a2f40a16c2cbd80c1a824aad7cb082e4@149.102.146.252:26656,dbe9c383a709881f6431242de2d805d6f0f60c9e@65.109.52.156:7656,d01fb8d008cb5f194bc27c054e0246c4357256b3@31.7.196.72:26656,91c0b06f0539348a412e637ebb8208a1acdb71a9@178.162.165.193:21095,bac90a590452337700e0033315e96430d19a3ffa@23.106.238.167:26656"


sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.acred/config/config.toml
```

<br>

## Configure service file for node daemon [Copy+paste the following lines together]
```
cat << EOF | sudo tee -a /etc/systemd/system/acred.service
[Unit]
Description=acred daemon
After=network-online.target

[Service]
User=node
ExecStart=/home/node/go/bin/acred start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

[Service]
LimitNOFILE=1048576
EOF
```

<br>

## Enable + Start the service
`sudo systemctl enable acred.service`

`sudo systemctl start acred`

<br>

## Confirm service status
`sudo systemctl status acred`

<br>

## Monitor daemon logs while service is running
`journalctl -fu acred -ocat`

**---------------------------------------------------------**

<br>

## State-Sync config  [copy+paste each line or block of text in full]

`sudo systemctl stop acred`

`acred tendermint unsafe-reset-all --home $HOME/.acred --keep-addr-book`

`SNAP_RPC="https://rpc-acrechain.nodeist.net:443"`

```
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
```

```
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.acred/config/config.toml
```

`sudo systemctl start acred && journalctl -fu acred -ocat`

#### *[may take some time to start... let it sit for maybe 30 minutes and if it isn't progressing or finished by then move on to next step]*

<br>

## Snapshot config [skip this step if state sync was successful]
`sudo systemctl stop acred`

`acred tendermint unsafe-reset-all --home $HOME/.acred --keep-addr-book`

`curl -L https://snap.nodeist.net/acre/acre.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.acred --strip-components 2`

`sudo systemctl start acred && journalctl -fu acred -ocat`

<br>

**---------------------------------------------------------**

# **NOTE -- CONFIRM NODE IS FULLY SYNCED/CAUGHT UP BEFORE CONTINUING**

**---------------------------------------------------------**

<br>

## Restore backed up config+validator 
### Run from the server
#### *If response 'true' your node is not yet caught up - wait for sync or check why it is not yet synced*
#### *If response 'false' your node is caught up*

```
curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up'
```

<br>

## Delete contents of config folder
`sudo systemctl stop acred`

`sudo systemctl disable acred`

`rm ~/.acred/config/*`

<br>

## Confirm deletion [should show no response]
`cd ~/.acred/config && ls`

<br>

**---------------------------------------------------------**
# *Disconnect from server or open another WSL terminal*
**---------------------------------------------------------**

<br>

## Restore config folder from backup [run commands from WSL on your local machine]
`scp -r ~/config node@<server-ssh-info>:/home/node/.acred/`

`ssh node@<server-ssh-info>`

<br>

## Reconnect to server, confirm config restored
`cd ~/.acred/config && ls`
#### Should see files restored here

<br>

## Configure permissions on config files
`sudo chown -R node:node ~/.acred/config`

`sudo chmod 644 ~/.acred/config/*`

`sudo chmod 600 ~/.acred/config/client.toml`

`sudo chmod 600 ~/.acred/config/node_key.json`

`sudo chmod 600 ~/.acred/config/priv_validator_key.json`

<br>

## Start service + confirm regular operation
`sudo systemctl enable acred`

`sudo systemctl start acred`

`journalctl -fu acred -ocat`
