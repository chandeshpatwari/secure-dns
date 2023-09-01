# cloudflared : may be used to run a local DNS over HTTPS server (DoH), i.e., a stub resolver.

# Use Service
Config : C:\Windows\system32\config\systemprofile\.cloudflared\config.yml
Command :
 - cloudflared.exe service install
 - Get-Service 'cloudflared' | Restart-Service -Verbose -Force

# Default Config Path
Config : $env:USERPROFILE\.cloudflared\config.yml
Command : cloudflared.exe

# Custom Config Path
Config : $env:USERPROFILE\.cloudflared\config.yml
Command : cloudflared.exe --config $env:USERPROFILE\.cloudflared\config.yml


# Default ServerAddresses
Config : -
Command : cloudflared.exe proxy-dns
> This One Doesn't Check if Port 53 is Pre-Engaged

- https://github.com/cloudflare/cloudflared
- https://wiki.archlinux.org/title/Cloudflared
- https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/dns-over-https-client