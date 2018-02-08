#!/bin/bash

# Copy sample config if one doesnt exist
if [[ ! -e /config/ocserv.conf]]; then
	cp /etc/ocserv/ocserv.conf.sample /config/ocserv.conf
fi

# Setup config
set -x \
	&& sed -i 's/\.\/sample\.passwd/\/config\/ocpasswd/' /config/ocserv.conf \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /config/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /config/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /config/ocserv.conf \
	&& sed -i '/^ipv4-network = /{s/192.168.1.0/192.168.99.0/}' /config/ocserv.conf \
	&& sed -i 's/192.168.1.2/8.8.8.8/' /config/ocserv.conf \
	&& sed -i 's/^route/#route/' /config/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /config/ocserv.conf \

##### Verify Variables #####
export LISTEN_PORT=$(echo "${LISTEN_PORT}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check PROXY_SUPPORT env var
if [[ ! -z "${LISTEN_PORT}" ]]; then
	echo "[info] LISTEN_PORT defined as '${LISTEN_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
	echo "Make sure you changed the 4443 port in container settings to expose the port you selected!" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] LISTEN_PORT not defined,(via -e LISTEN_PORT), defaulting to '4443'" | ts '%Y-%m-%d %H:%M:%.S'
	export LISTEN_PORT="4443"
fi

export TUNNEL_MODE=$(echo "${TUNNEL_MODE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check PROXY_SUPPORT env var
if [[ ! -z "${TUNNEL_MODE}" ]]; then
	echo "[info] TUNNEL_MODE defined as '${TUNNEL_MODE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] TUNNEL_MODE not defined,(via -e TUNNEL_MODE), defaulting to 'all'" | ts '%Y-%m-%d %H:%M:%.S'
	export TUNNEL_MODE="all"
fi

if [[ ${TUNNEL_MODE} == "all" ]]; then
	echo "[info] Tunnel mode is all, ignoring TUNNEL_ROUTES. If you want to define specific routes, change TUNNEL_MODE to split-include" | ts '%Y-%m-%d %H:%M:%.S'
elif [[ ${TUNNEL_MODE} == "split-include" ]]; then
	# strip whitespace from start and end of SPLIT_DNS_DOMAINS
	export TUNNEL_ROUTES=$(echo "${TUNNEL_ROUTES}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	# Check SPLIT_DNS_DOMAINS env var and exit if not defined
	if [[ ! -z "${TUNNEL_ROUTES}" ]]; then
		echo "[info] TUNNEL_ROUTES defined as '${TUNNEL_ROUTES}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[err] TUNNEL_ROUTES not defined (via -e TUNNEL_ROUTES), but TUNNEL_MODE is defined as split-include" | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi
fi

# strip whitespace from start and end of PROXY_SUPPORT
export PROXY_SUPPORT=$(echo "${PROXY_SUPPORT}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check PROXY_SUPPORT env var
if [[ ! -z "${PROXY_SUPPORT}" ]]; then
	echo "[info] PROXY_SUPPORT defined as '${PROXY_SUPPORT}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] PROXY_SUPPORT not defined,(via -e PROXY_SUPPORT), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export PROXY_SUPPORT="no"
fi

# strip whitespace from start and end of DNS_SERVERS
export DNS_SERVERS=$(echo "${DNS_SERVERS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check DNS_SERVERS env var
if [[ ! -z "${DNS_SERVERS}" ]]; then
		echo "[info] DNS_SERVERS defined as '${DNS_SERVERS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] DNS_SERVERS not defined (via -e DNS_SERVERS), defaulting to Google and FreeDNS name servers" | ts '%Y-%m-%d %H:%M:%.S'
		export DNS_SERVERS="8.8.8.8,37.235.1.174,8.8.4.4,37.235.1.177"
fi

# strip whitespace from start and end of SPLIT_DNS
export SPLIT_DNS=$(echo "${SPLIT_DNS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check SPLIT_DNS env var
if [[ ! -z "${SPLIT_DNS}" ]]; then
	echo "[info] SPLIT_DNS defined as '${SPLIT_DNS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] SPLIT_DNS not defined,(via -e SPLIT_DNS), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export SPLIT_DNS="no"
fi

if [[ ${SPLIT_DNS} == "yes" ]]; then
	# strip whitespace from start and end of SPLIT_DNS_DOMAINS
	export SPLIT_DNS_DOMAINS=$(echo "${SPLIT_DNS_DOMAINS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	# Check SPLIT_DNS_DOMAINS env var and exit if not defined
	if [[ ! -z "${SPLIT_DNS_DOMAINS}" ]]; then
		echo "[info] SPLIT_DNS_DOMAINS defined as '${SPLIT_DNS_DOMAINS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[err] SPLIT_DNS_DOMAINS not defined (via -e SPLIT_DNS_DOMAINS), but SPLIT_DNS is defined as yes" | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi
fi


##### Process Variables #####
# Add Default No-Routes
echo "no-route=192.168.0.0/255.255.0.0" >> /config/ocserv.conf
echo "no-route=10.0.0.0/255.0.0.0" >> /config/ocserv.conf
echo "no-route=172.16.0.0/255.240.0.0" >> /config/ocserv.conf
echo "no-route=127.0.0.0/255.0.0.0" >> /config/ocserv.conf

if [[ ${LISTEN_PORT} != "4443" ]]; then
	sed -i 's/^no-route/#no-route/' /config/ocserv.conf
fi

if [[ ${TUNNEL_MODE} == "all" ]]; then
	echo "[info] Tunneling all traffic through VPN" | ts '%Y-%m-%d %H:%M:%.S'
elif [[ ${TUNNEL_MODE} == "split-include" ]]; then
	echo "[info] Tunneling routes $TUNNEL_ROUTES through VPN" | ts '%Y-%m-%d %H:%M:%.S'
	# split comma seperated string into list from NAME_SERVERS env variable
	IFS=',' read -ra tunnel_route_list <<< "${TUNNEL_ROUTES}"
	# process name servers in the list
	for tunnel_route_item in "${tunnel_route_list[@]}"; do
		# strip whitespace from start and end of lan_network_item
		tunnel_route_item=$(echo "${tunnel_route_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

		echo "[info] Adding route=${tunnel_route_item} to ocserv.conf" | ts '%Y-%m-%d %H:%M:%.S'
		echo "route=${tunnel_route_item}" >> /config/ocserv.conf
	done
fi

# Process PROXY_SUPPORT env var
if [[ $PROXY_SUPPORT == "yes" ]]; then
	# Set listen-proxy-proto = yes
	sed -i 's/^#listen-proxy-proto/listen-proxy-proto/' /config/ocserv.conf
fi

# Add DNS_SERVERS to ocserv conf
# split comma seperated string into list from NAME_SERVERS env variable
IFS=',' read -ra name_server_list <<< "${DNS_SERVERS}"
# process name servers in the list
for name_server_item in "${name_server_list[@]}"; do
	# strip whitespace from start and end of lan_network_item
	name_server_item=$(echo "${name_server_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

	echo "[info] Adding dns = ${name_server_item} to ocserv.conf" | ts '%Y-%m-%d %H:%M:%.S'
	echo "dns = ${name_server_item}" >> /config/ocserv.conf
done

# Process SPLIT_DNS env var
if [[ $SPLIT_DNS == "yes" ]]; then
	# split comma seperated string into list from SPLIT_DNS_DOMAINS env variable
	IFS=',' read -ra split_domain_list <<< "${SPLIT_DNS_DOMAINS}"
	# process name servers in the list
	for split_domain_item in "${split_domain_list[@]}"; do
		# strip whitespace from start and end of lan_network_item
		split_domain_item=$(echo "${split_domain_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

		echo "[info] Adding split-dns = ${split_domain_item} to ocserv.conf" | ts '%Y-%m-%d %H:%M:%.S'
		echo "split-dns = ${split_domain_item}" >> /config/ocserv.conf
fi

if [ ! -f /config/certs/server-key.pem ] || [ ! -f /config/certs/server-cert.pem ]; then
	# No certs found
	echo "[info] No certificates were found, creating them from provided or default values" | ts '%Y-%m-%d %H:%M:%.S'
	
	# Check environment variables
	if [ -z "$CA_CN" ]; then
		CA_CN="VPN CA"
	fi

	if [ -z "$CA_ORG" ]; then
		CA_ORG="Big Corp"
	fi

	if [ -z "$CA_DAYS" ]; then
		CA_DAYS=9999
	fi

	if [ -z "$SRV_CN" ]; then
		SRV_CN="www.example.com"
	fi

	if [ -z "$SRV_ORG" ]; then
		SRV_ORG="MyCompany"
	fi

	if [ -z "$SRV_DAYS" ]; then
		SRV_DAYS=9999
	fi

	# Generate certs one
	mkdir /config/certs
	cd /config/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "$CA_CN"
	organization = "$CA_ORG"
	serial = 1
	expiration_days = $CA_DAYS
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem 
	cat > server.tmpl <<-EOSRV
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"
