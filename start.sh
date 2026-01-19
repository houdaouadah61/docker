#!/bin/bash
set -euo pipefail

# Mes identifiants (je peux aussi les changer avec -e quand je lance docker run)
BASIC_USER="${BASIC_USER:-houdadh}"
BASIC_PASS="${BASIC_PASS:-Helloearth1234}"

DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-houdadh}"
DB_PASS="${MYSQL_PASSWORD:-Helloearth1234}"

AUTO_INDEX="${AUTO_INDEX:-off}"

WP_DIR="/var/www/html/wordpress"
WP_URL="${WP_URL:-http://localhost/wordpress}"
WP_TITLE="${WP_TITLE:-Examen}"
WP_ADMIN_USER="${WP_ADMIN_USER:-houdadh}"
WP_ADMIN_PASS="${WP_ADMIN_PASS:-Helloearth1234}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-houdadh@example.com}"

# MariaDB a besoin du dossier /run/mysqld
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Login navigateur (Basic Auth)
htpasswd -bc /etc/apache2/.htpasswd "$BASIC_USER" "$BASIC_PASS"
chmod 640 /etc/apache2/.htpasswd

# Autoindex : je crée /files et j'active/désactive selon AUTO_INDEX
mkdir -p /var/www/html/files
if [[ "${AUTO_INDEX,,}" == "on" ]]; then
  cat > /etc/apache2/conf-enabled/zz-files-autoindex.conf <<'EOF'
<Directory /var/www/html/files>
    Options +Indexes +FollowSymLinks
</Directory>
EOF
else
  cat > /etc/apache2/conf-enabled/zz-files-autoindex.conf <<'EOF'
<Directory /var/www/html/files>
    Options -Indexes +FollowSymLinks
</Directory>
EOF
fi

# Je lance supervisor (il démarre Apache + MariaDB)
supervisord -c /etc/supervisor/conf.d/supervisor.conf &

# J'attends que la base démarre avant de créer DB/user
echo "Attente de MariaDB..."
until mysqladmin ping -uroot --silent >/dev/null 2>&1; do
  sleep 1
done

# Je crée la base + un utilisateur + les droits (pour WordPress et phpMyAdmin)
mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Config WordPress -> DB (si wp-config n'existe pas)
if [[ ! -f "$WP_DIR/wp-config.php" ]]; then
  cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
  sed -i "s/database_name_here/${DB_NAME}/" "$WP_DIR/wp-config.php"
  sed -i "s/username_here/${DB_USER}/" "$WP_DIR/wp-config.php"
  sed -i "s/password_here/${DB_PASS}/" "$WP_DIR/wp-config.php"
fi

# Installer WordPress automatiquement (une seule fois) + activer inscription
if command -v wp >/dev/null 2>&1; then
  if ! wp core is-installed --allow-root --path="$WP_DIR" >/dev/null 2>&1; then
    wp core install \
      --url="$WP_URL" \
      --title="$WP_TITLE" \
      --admin_user="$WP_ADMIN_USER" \
      --admin_password="$WP_ADMIN_PASS" \
      --admin_email="$WP_ADMIN_EMAIL" \
      --skip-email \
      --allow-root \
      --path="$WP_DIR"
  fi

  # Je force "Register" à être activé (comme ça on peut créer un compte)
  wp option update users_can_register 1 --allow-root --path="$WP_DIR"
  wp option update default_role subscriber --allow-root --path="$WP_DIR"

  # Au cas où WordPress garde une ancienne URL (ex: localhost:8080), je la remets
  wp option update home "$WP_URL" --allow-root --path="$WP_DIR"
  wp option update siteurl "$WP_URL" --allow-root --path="$WP_DIR"
fi

# Je laisse tourner le conteneur
wait
