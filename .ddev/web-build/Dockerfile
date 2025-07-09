COPY www.conf /etc/php/*/fpm/pool.d/www.conf
COPY apache-site.conf /etc/apache2/sites-enabled/apache-site.conf
COPY mpm_event.conf /etc/apache2/mods-available/mpm_event.conf

# Set HOME environment variable to fix permission issues
ENV HOME=/var/www/html

