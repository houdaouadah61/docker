# Je dois utiliser Debian Buster
FROM debian:buster-slim

# Pour éviter les questions pendant apt install
ENV DEBIAN_FRONTEND=noninteractive

# Buster est ancien, donc j'utilise les dépôts archive (sinon apt-get update fait 404)
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list \
 && sed -i 's|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
 && sed -i '/buster-updates/d' /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid

# J'installe tout dans un seul conteneur :
# Apache + PHP (pour WordPress/phpMyAdmin) + MariaDB + supervisor (pour lancer plusieurs services)
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 apache2-utils \
    mariadb-server \
    supervisor \
    wget unzip tar ca-certificates \
    php7.3 libapache2-mod-php7.3 \
    php7.3-mysql php7.3-cli php7.3-mbstring php7.3-xml php7.3-zip \
    && rm -rf /var/lib/apt/lists/*

# Je télécharge WordPress
RUN wget -O /tmp/wordpress.zip https://wordpress.org/latest.zip \
 && unzip /tmp/wordpress.zip -d /var/www/html/ \
 && rm -f /tmp/wordpress.zip \
 && chown -R www-data:www-data /var/www/html/wordpress

# Je télécharge phpMyAdmin
RUN wget -O /tmp/pma.tar.gz https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
 && tar -xzf /tmp/pma.tar.gz -C /var/www/html/ \
 && rm -f /tmp/pma.tar.gz \
 && mv /var/www/html/phpMyAdmin-*-all-languages /var/www/html/phpmyadmin \
 && chown -R www-data:www-data /var/www/html/phpmyadmin

# WP-CLI me sert à auto-installer WordPress et activer l'inscription
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

# Je copie mes configs
COPY apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 3306

# Au démarrage je lance mon script (qui lance supervisor, DB, etc.)
CMD ["/start.sh"]