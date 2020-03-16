[preview]: https://raw.githubusercontent.com/MarkusMcNugen/docker-templates/master/openconnect/ocserv-icon.png "Custom ocserv icon"

![alt text][preview]

# OpenConnect VPN Server with Active Directory authentication
OpenConnect VPN server is an SSL VPN server that is secure, small, fast and configurable. It implements the OpenConnect SSL VPN protocol and has also (currently experimental) compatibility with clients using the AnyConnect SSL VPN protocol. The OpenConnect protocol provides a dual TCP/UDP VPN channel and uses the standard IETF security protocols to secure it. The OpenConnect client is multi-platform and available [here](http://www.infradead.org/openconnect/). Alternatively, you can try connecting using the official Cisco AnyConnect client (Confirmed working with AnyConnect 4.802045).

[Homepage](https://ocserv.gitlab.io/www/platforms.html)
[Documentation](https://ocserv.gitlab.io/www/manual.html)
[Source](https://gitlab.com/ocserv/ocserv)

# Docker Features
* Base: Debian Latest
* Latest OpenConnect Server 0.12.2
* LDAP/Active Directory authentication with libpam-ldap
* Size: 167MB
* Customizing the DNS servers used for queries over the VPN
* Supports tunneling all traffic over the VPN or tunneling only specific routes via split-include
* Config directory can be mounted to a host directory for persistence 
* Create certs automatically using default or provided values, or drop your own certs in /config/certs

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it. It needs a fair few environment variables, so I suggest using docker-compose.

## Quick Start
If you have not already done so, install docker-compose in according with its [documentation.](https://docs.docker.com/compose/install/)

In an empty directory, create a file called `docker-compose.yaml` and insert the below contents, substituting values suitable for your environment:
```docker
version: "3"

services:
  ocserv:
    container_name: ocserv
    image: morganonbass/ocserv-ldap:latest
    ports:
      - "443:443/tcp"
      - "443:443/udp"
    environment:
      LISTEN_PORT: 443
      TUNNEL_MODE: 'split_include'
      TUNNEL_ROUTES: '192.168.1.0/24, 192.168.69.0/24'
      DNS_SERVERS: 192.168.1.1
      SPLIT_DNS_DOMAINS: 'internal.domain.com'
      CLIENTNET: 192.168.248.0
      CLIENTNETMASK: 255.255.255.128
      BASEDN: 'dc=example,dc=com'
      LDAPURI: 'ldap://192.168.1.1/'
      BINDDN: 'CN=ocserv,CN=Users,DC=example,DC=com'
      BINDPW: 'aSuperSecurePassword'
      SEARCHSCOPE: 'sub'
      PAM_LOGIN_ATTRIBUTE: 'userPrincipalName'
      CA_CN: 'VPN CA'
      CA_ORG: 'OCSERV'
      CA_DAYS: 9999 
      SRV_CN: 'vpn.example.com'
      SRV_ORG: 'Example Company'
      SRV_DAYS: 9999
    volumes:
      - './config/:/config/'
    cap_add:
      - NET_ADMIN
    privileged: true
    restart: unless-stopped
```
Then, start the vpn service like so:
```
docker-compose up -d
```

## Using your own certificates
On start, the server checks for the following files:
```
/config/server-key.pem
/config/server-cert.pem
```
If these do not exist, a self signed certificate will be created. You may of course place your own signed certificates at this location.

## Advanced Configuration:
All of the relevant config files are in the /config volume. You may edit them to make use of more of Openconnect's features. Some advanced features include setting up site to site VPN links, User Groups, Proxy Protocol support and more.

# Variables
## Environment Variables
| Variable | Required | Function | Example |
|----------|----------|----------|----------|
|`LISTEN_PORT`| No | Listening port for VPN connections|`443`|
|`DNS_SERVERS`| No | Comma delimited name servers |`8.8.8.8,8.8.4.4`|
|`TUNNEL_MODE`| No | Tunnel mode (all / split-include) |`split-include`|
|`TUNNEL_ROUTES`| No | Comma delimited tunnel routes in CIDR notation |`192.168.1.0/24`|
|`SPLIT_DNS_DOMAINS`| No | Comma delimited dns domains |`example.com`|
|`CLIENTNET`| No | Network from which to assign client IPs |`192.168.255.0`|
|`CLIENTNETMASK`| No | Client subnet mask |`255.255.255.0`|
|`BASEDN`| Yes | Base DN for LDAP Search |`dc=example,dc=com`|
|`LDAPURI`| Yes | URI of LDAP Server |`ldap://192.168.1.1`|
|`BINDDN`| Yes | Account to bind PAM to LDAP |`CN=ocserv,CN=Users,DC=example,DC=com`|
|`BINDPW`| Yes | Password for the bind account |`hunter2`|
|`SEARCHSCOPE`| No | LDAP Search Scope (sub / one / base) |`sub`|
|`PAM_LOGIN_ATTRIBUTE`| No | LDAP Attribute to match - what your user will put in the username field of their client (sAMAccountName / userPrincipalName / uid) | `userPrincipalName`|

## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `config` | No | OpenConnect config files | `/your/config/path/:/config`|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `443` | TCP | Yes | OpenConnect server TCP listening port | `443:443`|
| `443` | UDP | Yes | OpenConnect server UDP listening port | `443:443/udp`|

## Login and Logout Log Messages
After a user successfully logins to the VPN a message will be logged in the docker log.<br>
*Example of login message:*
```
[info] User bob Connected - Server: 192.168.1.165 VPN IP: 192.168.255.194 Remote IP: 107.92.120.188 
```

*Example of logoff message:*
```
[info] User bob Disconnected - Bytes In: 175856 Bytes Out: 4746819 Duration:63
```

# Issues
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.
