# Fix DNS Port Conflict on Ubuntu

Ubuntu's `systemd-resolved` listens on port 53 by default, which conflicts with Pi-hole. Run these commands to fix it:

```bash
# Disable the DNS stub listener
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf

# Point resolv.conf to the full resolver
sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'

# Restart the resolver
sudo systemctl restart systemd-resolved
```

After this, port 53 will be free for Pi-hole to bind.
