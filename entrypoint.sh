#!/bin/bash
set -e

# Defaults
ADMIN_USER=${ADMIN_USER:-admin}
MAIL_SERVER=${MAIL_SERVER:-smtp}
POSTGRES_HOST=${POSTGRES_HOST:-postgres}
POSTGRES_DB=${POSTGRES_DB:-pdns}
POSTGRES_USER=${POSTGRES_USER:-pdns}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pdns}
PDNS_API_HOST=${PDNS_API_HOST:-172.17.0.1}
PDNS_API_PORT=${PDNS_API_PORT:-8081}
PDNS_API_KEY=${PDNS_API_KEY:-unset}

mkdir -p /data

sed -i -e "s/^mailhub=.*$/mailhub=${MAIL_SERVER}/" /etc/ssmtp/ssmtp.conf

if [ ! -f /data/config.ini ]; then
	echo "Creating initial config file..."
	cp /srv/dns-ui/config/config.ini.orig /data/config.ini
fi
ln -sf /data/config.ini /srv/dns-ui/config/

if grep -q '^; AUTOCONFIG_ENABLED=yes$' /data/config.ini; then
	echo "Updating configuration..."
	sed -e "s/^\(dsn\s*=\s*\"pgsql:host=\)[^;]\+\(;dbname=\)[^;]\+\"$/\1${POSTGRES_HOST}\2${POSTGRES_DB}\"/"               \
	    -e "s/^\(username\s*=\s*\"\).*\"$/\1${POSTGRES_USER}\"/"                                                           \
	    -e "s/^\(password\s*=\s*\"\).*\"$/\1${POSTGRES_PASSWORD}\"/"                                                       \
	    -e "s/^\(api_url\s*=\s*\"http:\/\/\).*\(\/api\/v1\/servers\/localhost\"\)$/\1${PDNS_API_HOST}:${PDNS_API_PORT}\2/" \
	    -e "s/^\(api_key\s*=\s*\"\).*\"$/\1${PDNS_API_KEY}\"/"                                                             \
	    -i /data/config.ini
else
	echo "Auto config update disabled... skipping."
fi

if ! grep -q 'INSERT INTO "user"' /srv/dns-ui/migrations/002.php; then
	echo "Adding initial user creation to db migrations..."
	sed -i '/\}$/{e cat -'$'\n''}' /srv/dns-ui/migrations/002.php <<-EOF
		\$this->database->prepare('
		INSERT INTO "user" (uid, name, email, active, admin, auth_realm)
			VALUES (?, ?, ?, ?, ?, ?)
		')->execute(
			array("${ADMIN_USER}", "Admin User", "admin@example.com", 1, 1, "local")
		);
	EOF
fi

while ! nc -z "$POSTGRES_HOST" 5432; do
	echo "Waiting for database..."
	sleep 1
done

echo "Starting Caddy..."
exec /usr/bin/caddy --conf /etc/Caddyfile --log stdout

