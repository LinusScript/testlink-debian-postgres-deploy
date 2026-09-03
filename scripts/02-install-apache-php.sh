#!/usr/bin/env bash
# Schritt 2: Apache + PHP (mod_php, MPM prefork) installieren.
# Siehe docs/installation/02-apache.md und 03-php.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

require_root
export DEBIAN_FRONTEND=noninteractive

log "Apache installieren"
apt-get update
apt-get install -y apache2

log "MPM auf 'prefork' umstellen (Voraussetzung fuer mod_php)"
a2dismod mpm_event >/dev/null 2>&1 || true
a2enmod mpm_prefork

log "PHP und benoetigte Erweiterungen installieren"
apt-get install -y \
  php \
  libapache2-mod-php \
  php-pgsql \
  php-gd \
  php-curl \
  php-mbstring \
  php-xml \
  php-zip \
  php-ldap

log "Apache-Module aktivieren"
a2enmod rewrite
a2enmod php* >/dev/null 2>&1 || true

log "Apache neu starten"
apache2ctl configtest
systemctl restart apache2
systemctl enable apache2 >/dev/null

log "Kontrolle:"
php -v
apache2 -v
echo "Geladene PHP-Erweiterungen (relevant fuer TestLink):"
php -m | grep -Ei 'pgsql|gd|curl|mbstring|xml|zip|ldap|json' || true
