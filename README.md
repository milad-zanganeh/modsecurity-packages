# Nginx ModSecurity Packages

Builds Nginx with ModSecurity v3 and the Core Rule Set (CRS) for Ubuntu and Debian.

## Supported distributions

- Ubuntu 20.04 (Focal)
- Ubuntu 22.04 (Jammy)
- Ubuntu 24.04 (Noble)
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

## Install from Cloudsmith repository (recommended)

We also publish packages to a Cloudsmith apt repository. This lets you install and update via your system package manager.

### Quick setup (auto-detect)

```bash
curl -1sLf \
  'https://dl.cloudsmith.io/public/nginx/modsecurity/setup.deb.sh' \
  | sudo -E bash
```

### Force specific distro/codename/arch/component (optional)

```bash
curl -1sLf \
  'https://dl.cloudsmith.io/public/nginx/modsecurity/setup.deb.sh' \
  | sudo -E distro=DISTRO codename=CODENAME arch=ARCH component=COMPONENT bash
```

### Manual setup (alternative)

```bash
apt-get install -y debian-keyring  # debian only
apt-get install -y debian-archive-keyring  # debian only
apt-get install -y apt-transport-https

# For Debian Stretch, Ubuntu 20.04 and later
keyring_location=/usr/share/keyrings/nginx-modsecurity-archive-keyring.gpg
# For Debian Jessie, Ubuntu 15.10 and earlier
keyring_location=/etc/apt/trusted.gpg.d/nginx-modsecurity.gpg

curl -1sLf 'https://dl.cloudsmith.io/public/nginx/modsecurity/gpg.96896FFB30D18241.key' | gpg --dearmor >> ${keyring_location}
curl -1sLf 'https://dl.cloudsmith.io/public/nginx/modsecurity/config.deb.txt?distro=ubuntu&codename=xenial&component=main' > /etc/apt/sources.list.d/nginx-modsecurity.list
sudo chmod 644 ${keyring_location}
sudo chmod 644 /etc/apt/sources.list.d/nginx-modsecurity.list
apt-get update
```

Note: Replace `ubuntu`, `xenial` and `main` above with your actual distribution, codename and component.

## Install deb package directly

On the target machine download the latest version of deb file. see [Releases](https://github.com/milad-zanganeh/modsecurity-packages/releases)

## Verify checksums

After downloading a package, you can verify it:

```bash
md5sum nginx_*.deb
```

Install it using cli:

```bash
sudo dpkg -i ./nginx_*.deb && apt install -f 
```


## Enable ModSecurity in Nginx

Add a server block similar to this and reload Nginx:

```nginx
server {
    ...
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/main.conf;
    ...

    location / {
        ...
    }
}
```
