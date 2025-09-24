#!/bin/bash
set -e 

export DEBIAN_FRONTEND=noninteractive
CI_PROJECT_DIR=$PWD
NGINX_VERSION_REQ=$(echo "$TAG_NAME" | sed -E 's/^nginx-//; s/^[vV]//')


apt update && apt install -y \
    software-properties-common \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    pkg-config \
    wget

DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
RELEASE=$(lsb_release -cs)


curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$DISTRO $RELEASE nginx" \
    | tee /etc/apt/sources.list.d/nginx.list \
    && echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$DISTRO $RELEASE nginx" \
    >> /etc/apt/sources.list.d/nginx.list 

/bin/bash -c 'echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n"  | tee /etc/apt/preferences.d/99nginx' && apt update

SRC_VER=$(apt-cache showsrc nginx | awk '/^Version:/ {print $2}' | grep -E "^${NGINX_VERSION_REQ}([~+:-]|$)" | head -n1 || true)
echo "SRC_VER: $SRC_VER"

if [ -z "$SRC_VER" ]; then
    echo "ERROR: Requested NGINX version '$NGINX_VERSION_REQ' not found for $DISTRO $RELEASE in nginx.org repository."
    exit 1
fi

apt install -y \
    build-essential \
    dpkg-dev \
    devscripts \
    debhelper \
    fakeroot \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    libyajl-dev \
    autoconf \
    automake \
    libtool \
    libcurl4-openssl-dev \
    libxml2-dev \
    libgeoip-dev \
    libpcre2-dev \
    quilt


mkdir -p /nginx && apt update && (cd /nginx && apt source nginx=$NGINX_VERSION_REQ && mv  $(ls -d /nginx/nginx-*) /nginx/nginx-latest)
cp $CI_PROJECT_DIR/rules /nginx/nginx-latest/debian/rules

git clone --depth 1 -b v3.0.8 https://github.com/SpiderLabs/ModSecurity.git \
    && (cd ModSecurity \
    && git submodule update --init \
    && ./build.sh \
    && ./configure --with-yajl \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /usr/local/modsecurity/etc \
    && cp modsecurity.conf-recommended /usr/local/modsecurity/etc/modsecurity.conf \
    && wget -O /usr/local/modsecurity/etc/unicode.mapping https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping)

git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && mv ModSecurity-nginx /usr/src/modsecurity

git clone --depth 1 https://github.com/coreruleset/coreruleset.git /etc/nginx/modsec

cp $CI_PROJECT_DIR/modsec/main.conf /etc/nginx/modsec/main.conf

(cd /nginx/nginx-latest && dpkg-buildpackage -b -us -uc)

mkdir -p $CI_PROJECT_DIR/out
cp /nginx/nginx_*.deb $CI_PROJECT_DIR/out/ || { echo "No non-dbg .deb found"; exit 1; }

md5sum $CI_PROJECT_DIR/out/*.deb 

echo "Setup CLOUD_CLI"
apt update && apt install python3 python3-venv -y  &&   python3 -m venv . && . bin/activate && pip3 install cloudsmith-cli

cloudsmith push deb "nginx/modsecurity/$DISTRO/$RELEASE" "$(ls $CI_PROJECT_DIR/out/*.deb)" || echo "WARNING: Cloudsmith push failed (non-fatal).
