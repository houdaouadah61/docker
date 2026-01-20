#!/bin/bash
set -euo pipefail

# Variables DB 
DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-houdadh}"
DB_PASS="${MYSQL_PASSWORD:-Helloearth1234}"

WP_DIR="/var/www/html/wordpress"

# MariaDB 
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Démarrer MariaDB
service mariadb start 2>/dev/null || service mysql start 2>/dev/null || true

# Attendre que MariaDB soit prête
echo "Attente de MariaDB..."
until mysqladmin --protocol=socket ping -uroot --silent >/dev/null 2>&1; do
  sleep 1
done

# Créer la base + l'utilisateur + droits (sans backticks qui cassent)
mysql --protocol=socket -uroot -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql --protocol=socket -uroot -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql --protocol=socket -uroot -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Config WordPress (si wp-config.php n'existe pas)
if [ ! -f "${WP_DIR}/wp-config.php" ]; then
  cp "${WP_DIR}/wp-config-sample.php" "${WP_DIR}/wp-config.php"
  sed -i "s/database_name_here/${DB_NAME}/" "${WP_DIR}/wp-config.php"
  sed -i "s/username_here/${DB_USER}/" "${WP_DIR}/wp-config.php"
  sed -i "s/password_here/${DB_PASS}/" "${WP_DIR}/wp-config.php"
fi

chown -R www-data:www-data "${WP_DIR}"

# Lancer Apache au premier plan
exec apachectl -D FOREGROUND

