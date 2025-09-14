export DEBIAN_FRONTEND=noninteractive
CI_PROJECT_DIR=$PWD
set -e 

apt update && apt install -y \
    build-essential \
    dpkg-dev \
    devscripts \
    debhelper \
    fakeroot \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    software-properties-common \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    pkg-config \
    libyajl-dev \
    autoconf \
    automake \
    libtool \
    libcurl4-openssl-dev \
    libxml2-dev \
    libgeoip-dev \
    libpcre2-dev \
    quilt \
    vim \
    wget

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) nginx" \
    | tee /etc/apt/sources.list.d/nginx.list \
    && echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) nginx" \
    >> /etc/apt/sources.list.d/nginx.list

/bin/bash -c 'echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n"  | tee /etc/apt/preferences.d/99nginx'


mkdir -p /nginx && apt update && (cd /nginx && apt source nginx && mv  $(ls -d /nginx/nginx-*) /nginx/nginx-latest)
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
md5sum /nginx/*.deb

ls /nginx/nginx*.deb
