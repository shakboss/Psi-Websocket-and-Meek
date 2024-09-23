#!/bin/bash

read -p "Do you wish to install this program? (y / n)? " yn
    if [[ "$yn" =~ 'n' ]]; then exit; fi

echo 'Server must have x86_64 architecture to continue!!'
echo 'No Ampere(Arm\aarch64) and x86 servers supported at the moment!!'
echo 'Enter the domain for FRONTED-MEEK-OSSH (Fastly Endpoint) (Fastly,azure and other CDNs)! (Example: somedomain.com.global.prod.fastly.net)'
read fastly_endpoint
echo 'Enter the domain for FRONTED-WSS-OSSH (Cloudflare\Gcore mainly, websocket)! (Example: cf.somedomain.com)'
read cf_url
echo 'Enter the domain for local caching ! (Example: 1.somedomain.com)'
read local_cache
ifconfig
echo 'Enter your interface name (Enter only one)! (Example: venet0, esp0s3)'
read interf

cd /root
apt update
apt install unzip cmake openssl screen wget nginx curl jq ufw -y
mkdir -p /etc/ssl/v2ray/ && sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/v2ray/priv.key -out /etc/ssl/v2ray/cert.pub -subj "/C=US/ST=Oregon/L=Portland/O=TranSystems/OU=ProVPN/CN=cosmos.com"

curl https://raw.githubusercontent.com/mukswilly/psicore-binaries/master/psiphond/psiphond -o psiphond
chmod +x psiphond
./psiphond -ipaddress 0.0.0.0 -protocol FRONTED-MEEK-OSSH:3001 -protocol FRONTED-WSS-OSSH:3002 generate

jq -c '.RunPacketTunnel = true' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
jq -c '.PacketTunnelEgressInterface = "'${interf}'"' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
entry=$(cat server-entry.dat | xxd -r -p)
echo ${entry:8} > entry.json
cf_url=$(echo '"'${cf_url}'"')
fastly_endpoint=$(echo '"'${fastly_endpoint}'"')
jq -c ".meekFrontingHosts = ["${fastly_endpoint}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.meekFrontingAddresses = ["speedtest.net","image-sandbox.tidal.com","f.cloud.github.com","docs.github.com","linktr.ee","www.paypal.com"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c ".wsFrontingHosts = ["${cf_url}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.wsFrontingAddresses = ["cdnhealth.www.tinkoff.ru","mm.tinkoff.ru"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.meekServerPort = 443' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.wsServerPort = 443' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
#jq -c ".wsFrontingSNI = "${cf_url}"" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
entry1=$(cat entry.json | xxd -p)
entry2=$(echo 3020302030203020${entry1} | tr -d '[:space:]')
entry3=${entry2::-2}

echo ${entry3} > psi.html
mv psi.html /var/www/html/psi.html
screen -dmS psiphon ./psiphond run
