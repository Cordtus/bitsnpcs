# terminal text tools




---

**example**
list [name - version] of installed packages, saved in file `'packages'`

<details>
  <summary>example file</summary>
    
```
luci-proto-ipv6 - git-21.148.48881-79947af
luci-proto-ppp - git-21.158.38888-88b9d84
luci-ssl - git-20.244.36115-e10f954
luci-ssl - git-20.244.36115-e10f954
luci-theme-bootstrap - git-23.093.42704-b47268a
mii-tool - 2.10-1
mkf2fs - 1.14.0-3
mtd - 26
mwan3 - 2.11.6-1
nano - 7.2-2
netifd - 2022-08-25-76d2d41b-1
netperf - 2.7.0-3
nftables-json - 1.0.2-2.1
odhcp6c - 2022-08-05-7d21e8d8-18
openwrt-keyring - 2022-03-25-62471e69-3
opkg - 2022-02-24-d038e5b6-1
partx-utils - 2.37.4-1
ppp - 2.4.9.git-2021-01-04-3
nano - 7.2-2
ppp-mod-pppoe - 2.4.9.git-2021-01-04-3
procd - 2022-06-01-7a009685-2
procd-seccomp - 2022-06-01-7a009685-2
procd-ujail - 2022-06-01-7a009685-2
proto-bonding - 2021-04-09-3
px5g-wolfssl - 6.2
python3 - 3.10.9-1
nftables-json - 1.0.2-2.1
```
    
</details>
<br>

**workflow:** filter each line for name only, find/remove duplicate lines, condense list into single line of space-separated items, revert to line-separated list


---
<br>

**1)** filter and print first word [*string*] of each line, save to new file `'packages1'` and print

`$ awk '{print $1}' <file> >> packages1`<br>
`$ cat packages1`

<details>
    <summary><b>output</b></summary>

```
luci-proto-ipv6
luci-proto-ppp
luci-ssl
luci-ssl
luci-theme-bootstrap
mii-tool
mkf2fs
mtd
mwan3
nano
netifd
netperf
nftables-json
odhcp6c
openwrt-keyring
opkg
partx-utils
ppp
nano
ppp-mod-pppoe
procd
procd-seccomp
procd-ujail
proto-bonding
px5g-wolfssl
python3
nftables-json
```
</details>
<br>
<br>

**2*a*)** print duplicate lines [if any] with counts

`$ sort packages1 | uniq -cd`

<details>
  <summary><b>output</b></summary>

```
      2 luci-ssl
      2 nano
      2 nftables-json
```
</details>
<br>

**2*b*)** print and remove duplicate lines, save pruned output to new file `'packages1.1'` and print

`$ sort packages1 | uniq > packages1.1`<br>
`$ cat packages1.1`

<details>
  <summary><b>output</b></summary>

```
luci-proto-ipv6
luci-proto-ppp
luci-ssl
luci-theme-bootstrap
mii-tool
mkf2fs
mtd
mwan3
nano
netifd
netperf
nftables-json
odhcp6c
openwrt-keyring
opkg
partx-utils
ppp
ppp-mod-pppoe
procd
procd-seccomp
procd-ujail
proto-bonding
px5g-wolfssl
python3
```
</details>
<br>
<br>

**3)** combine all lines into single line separated by spaces, save to new file `'packages2'` and print

`$ cat packages1.1 | xargs >> packages2`<br>
`$ cat packages2`

<details>
  <summary><b>output</b></summary>

```
luci-proto-ipv6 luci-proto-ppp luci-ssl luci-theme-bootstrap mii-tool mkf2fs mtd mwan3 nano netifd netperf nftables-json odhcp6c openwrt-keyring opkg partx-utils ppp ppp-mod-pppoe procd procd-seccomp procd-ujail proto-bonding px5g-wolfssl python3
```
</details>
<br>
<br>

**4)** revert to line-separated list by replacing spaces with new line, save to new file `'packages3'` and print

`$ cat packages2 | tr " " "\n" >> packages3`<br>
`$ cat packages3`

<details>
  <summary><b>output</b></summary>

```
luci-proto-ipv6
luci-proto-ppp
luci-ssl
luci-theme-bootstrap
mii-tool
mkf2fs
mtd
mwan3
nano
netifd
netperf
nftables-json
odhcp6c
openwrt-keyring
opkg
partx-utils
ppp
ppp-mod-pppoe
procd
procd-seccomp
procd-ujail
proto-bonding
px5g-wolfssl
python3
```
</details>
