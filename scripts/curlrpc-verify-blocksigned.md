# search recent block for own validator signature

install dependencies if needed - `curl`, `grep`, `jq`


### *DO NOT SHARE* any part of `priv_validator_key.json` beyond what is used to set the variable
 
```
CONSADDR=$(cat ~/<.daemon>/config/priv_validator_key.json | jq '.address' -r)

curl -s <RPC URL>/block | jq '.result .block .last_commit .signatures[].validator_address' -r | grep $CONSADDR
```

negative result - no response <br>
positive result - returns valcons address [in hex format >> `AAAABBBBCCCCDDDD`]
