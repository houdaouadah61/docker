# Debian Buster (impose)
FROM debian:buster-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list \
 && sed -i 's|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
 && sed -i '/buster-updates/d' /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid

# Apache + PHP + MariaDB
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    mariadb-server \
    wget unzip tar ca-certificates \
    php7.3 libapache2-mod-php7.3 \
    php7.3-mysql php7.3-cli php7.3-mbstring php7.3-xml php7.3-zip \
 && rm -rf /var/lib/apt/lists/*

# Activer rewrite pour WordPress
RUN a2enmod rewrite

# Enlever le warning "Could not reliably determine the server's fully qualified domain name"
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && a2enconf servername

# Telecharger WordPress
RUN wget -O /tmp/wordpress.zip https://wordpress.org/latest.zip \
 && unzip /tmp/wordpress.zip -d /var/www/html/ \
 && rm -f /tmp/wordpress.zip \
 && chown -R www-data:www-data /var/www/html/wordpress

# Telecharger phpMyAdmin
RUN wget -O /tmp/pma.tar.gz https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
 && tar -xzf /tmp/pma.tar.gz -C /var/www/html/ \
 && rm -f /tmp/pma.tar.gz \
 && mv /var/www/html/phpMyAdmin-*-all-languages /var/www/html/phpmyadmin \
 && chown -R www-data:www-data /var/www/html/phpmyadmin

# Dossier /files + page d'accueil simple
RUN mkdir -p /var/www/html/files \
 && chown -R www-data:www-data /var/www/html/files \
 && printf '%s\n' \
'<!doctype html>' \
'<html><head><meta charset="utf-8"><title>Serveur OK</title></head>' \
'<body>' \
'<h1>Serveur OK ✅</h1>' \
'<p>Si tu vois ce texte, Apache + Docker fonctionnent.</p>' \
'<p>WordPress : /wordpress</p>' \
'<p>phpMyAdmin : /phpmyadmin</p>' \
'</body></html>' \
> /var/www/html/index.html

# Copier la conf Apache + script de demarrage
COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 3306

CMD ["/start.sh"]