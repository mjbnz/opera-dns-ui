FROM php:7.4-fpm

ENV DEBIAN_FRONTEND=noninteractive

# Install php extension build deps
RUN apt-get update -y \
 && apt-get upgrade -yq --no-install-recommends --no-install-suggests \
 && apt-get install -yq --no-install-recommends --no-install-suggests libldb-dev libldap2-dev libcurl4-openssl-dev libicu-dev libpq-dev postgresql-client netcat \
 && sed -i -e '$a\deb http://deb.debian.org/debian bullseye main' /etc/apt/sources.list \
 && apt-get update -y \
 && apt-get install -yq --no-install-recommends --no-install-suggests ssmtp \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
 && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
 && sed -i -e 's/^.*FromLineOverride=.*$/FromLineOverride=YES/' /etc/ssmtp/ssmtp.conf \
 && ( echo "sendmail_path = /usr/sbin/ssmtp -t" > /usr/local/etc/php/conf.d/docker-php-mail.ini )

RUN docker-php-ext-install pdo_pgsql pgsql ldap intl

# Install Caddy
RUN curl --silent --show-error --fail --location \
         --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
         "https://caddyserver.com/download/linux/amd64?plugins=http.expires,http.realip&license=personal" \
  | tar --no-same-owner -C /usr/bin/ -xz caddy \
 && chmod 0755 /usr/bin/caddy \
 && /usr/bin/caddy -version

# Install dns-ui
RUN mkdir -p /srv/dns-ui \
 && cd /srv/dns-ui \
 && curl -L -o - https://github.com/operasoftware/dns-ui/archive/master.tar.gz \
  | tar --strip-components=1 -zxv \
 && chown -R www-data:www-data .

COPY Caddyfile /etc/Caddyfile
COPY config.ini /srv/dns-ui/config/config.ini.orig
COPY entrypoint.sh /entrypoint

WORKDIR /srv/dns-ui/public_html

STOPSIGNAL SIGTERM

ENTRYPOINT ["/entrypoint"]

VOLUME /data
