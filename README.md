# opera-dns-ui
A self contained docker image with php-fpm & caddy for [Opera's PowerDNS Admin UI](https://github.com/operasoftware/dns-ui)

This image is intended to be used behind some form of reverse proxy responsible for Authentication. The proxy should set an `X-Auth-User` header with the authenticated username for the application. (the application's support for PHP authentication has been enabled, LDAP disabled).

An initial user is created during database initialisation by the application, specified by the `ADMIN_USER` environment variable.

### Environment variables:

|Variable Name|Default|Description|
|-|-|-|
|`ADMIN_USER`|`admin`|Initial admin username for DNS UI|
|`MAIL_SERVER`|`smtp`|SMTP mail server hostname for outgoing mail|
|`POSTGRES_HOST`|`postgres`|Postgresql database host|
|`POSTGRES_PORT`|`5432`|Postgresql database port|
|`POSTGRES_DB`|`dnsui`|Database name|
|`POSTGRES_USER`|`dnsui`|Database user/role|
|`POSTGRES_PASSWORD`|`dnsui`|Database password|
|`PDNS_API_HOST`|`172.17.0.1`|PowerDNS API host|
|`PDNS_API_PORT`|`8081`|PowerDNS API Port|
|`PDNS_API_KEY`|`change`|PowerDNS API key|

### Example docker invocation:

    docker run -d                                      \
           -e MAIL_SERVER=smtp.example.com             \
           -e POSTGRES_HOST=dbhost.example.com         \
           -e POSTGRES_PASSWORD=a-very-secret-password \
           -e PDNS_API_HOST=dns.example.com            \
           -e PDNS_API_KEY=a-very-secret-key           \
           -v /srv/dnsui:/data                         \
           --restart=unless-stopped                    \
       mjbnz/opera-dns-ui:latest

##### Parts and inspiration taken from:
* https://github.com/maxguru/operadns-ui-docker
* https://github.com/LolHens/docker-dns-ui
* https://bitpress.io/caddy-with-docker-and-php/
* https://github.com/stevepacker/docker-containers/tree/caddy-php7

