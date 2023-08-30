- A simple DNS proxy server that supports :
all existing DNS protocols including DNS-over-TLS, DNS-over-HTTPS, DNSCrypt, and DNS-over-QUIC.

# https://github.com/AdguardTeam/dnsproxy

# Config

- Fallback Servers(Optional)
- 8.8.8.8:53 
- 1.1.1.1:53

### Bootstrap (Required for DOH/DOT)
- "1.1.1.1:53"
- "8.8.8.8:53" # Default

# Plain DNS
- 8.8.8.8

# Plain UDP/TCP
- udp://dns.google
- tcp://dns.google

# Encrypted upstreams

## DNS-over-TLS
- tls://dns.adguard.com

## DNS-over-QUIC
- quic://dns.adguard.com

## DNS-over-HTTPS
- https://dns.adguard.com/dns-query
- https://dns.google/dns-query

### DNS-over-HTTPS /w forced HTTP/3
- h3://dns.google/dns-query

## DNSCrypt
- sdns://AQIAAAAAAAAAFDE3Ni4xMDMuMTMwLjEzMDo1NDQzINErR_JS3PLCu_iZEIbq95zkSV2LFsigxDIuUso_OQhzIjIuZG5zY3J5cHQuZGVmYXVsdC5uczEuYWRndWFyZC5jb20

## DNS-over-HTTPS
- sdns://AgcAAAAAAAAABzEuMC4wLjGgENk8mGSlIfMGXMOlIlCcKvq7AVgcrZxtjon911-ep0cg63Ul-I8NlFj4GplQGb_TTLiczclX57DvMV8Q-JdjgRgSZG5zLmNsb3VkZmxhcmUuY29tCi9kbnMtcXVlcnk



# Cloudlflare

# DOH
upstream:
- https://cloudflare-dns.com/dns-query
- https://one.one.one.one/dns-query
- https://1.0.0.1/dns-query
- https://1.1.1.1/dns-query
- https://2606:4700:4700::1111/dns-query
- https://2606:4700:4700::1001/dns-query

# DOT
upstream:
- tls://one.one.one.one
- tls://1.1.1.1
- tls://1.0.0.1
- tls://2606:4700:4700::1111 
- tls://2606:4700:4700::1001

# For DOT/DOH
bootstrap:
 - "1.1.1.1:53"
 - "1.0.0.1:53"

### /w HTTP/3 support (chooses it if it's faster)
http3: true

# Plain TCP/UDP Only
- udp://1.1.1.1
- tcp://1.1.1.1

# Plain
- 1.1.1.1
- 1.0.0.1
- 2606:4700:4700::1111
- 2606:4700:4700::1001
- cloudflare-dns.com
- one.one.one.one





dnsproxy.exe -l "::" -u "https://cloudflare-dns.com/dns-query" -b "1.1.1.1:53" --http3
