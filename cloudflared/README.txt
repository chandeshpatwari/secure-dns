# cloudflared : may be used to run a local DNS over HTTPS server (DoH), i.e., a stub resolver.

- https://github.com/cloudflare/cloudflared
- https://wiki.archlinux.org/title/Cloudflared
- https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/dns-over-https-client

# Use Service

# Default Config Path
$env:USERPROFILE\.cloudflared\config.yml
cloudflared.exe

# Custom Config Path
cloudflared.exe --config $env:USERPROFILE\.cloudflared\config.yml

# Default ServerAddresses
cloudflared.exe proxy-dns