#!/bin/bash
# ---
# Usage: ./script.sh Tunnel-Name(Endpoint-IP) Server-IP-Range(e.g 100.64.0.1/30) Client-IP-Range(e.g 100.64.0.2/30)
# ---
# Variablen
# Port of Endpoint
apt-get update
apt-get install -y wireguard resolvconf
PUBIP="23.156.104.122"
PORT=$(shuf -i 100-65035 -n 1)
umask 077
## Gen Wireguard Keys
RAND=$RANDOM
# Gen Server Keys
wg genkey > /tmp/$RAND
SERVER_PRIVKEY=$(cat /tmp/$RAND)
SERVER_PUBKEY=$(cat /tmp/$RAND | wg pubkey)
rm -f /tmp/$RAND
# Gen Client Keys
wg genkey > /tmp/$RAND
CLIENT_PRIVKEY=$(cat /tmp/$RAND)
CLIENT_PUBKEY=$(cat /tmp/$RAND | wg pubkey)
wg genkey > /tmp/$RAND
# Gen Global Keys
PRESHAREDKEY=$(wg genpsk)


touch /etc/wireguard/$1.conf
# Create Tunnel on Server Side
cat << EOF > /etc/wireguard/$1.conf
[Interface]
PrivateKey = ${SERVER_PRIVKEY}
Address = ${2}
ListenPort = ${PORT}
PostUp = sysctl -w net.ipv4.ip_forward=1; iptables -A FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT
MTU = 1500

[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHAREDKEY}
AllowedIPs = ${3}
EOF
# Create Tunnel Config of Client
mkdir -p /etc/wireguard/client-confs/
cat << EOF > /etc/wireguard/client-confs/$1.conf
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address = ${3}
Table = 11
MTU = 1500

[Peer]
PublicKey = ${SERVER_PUBKEY}
PresharedKey = ${PRESHAREDKEY}
Endpoint = ${PUBIP}:${PORT}
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0
EOF

echo "###"
echo "Client Config"
echo "###"
cat /etc/wireguard/client-confs/$1.conf
echo "###"
echo "###"
echo "###"
echo "Tunnel Created, script not done so do configure start and autostart by yourself!"
