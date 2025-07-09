# Create runtime user (1000) for K8s compatibility, regardless of build user
RUN if ! id -u 1000 >/dev/null 2>&1; then \
    groupadd --gid 1000 runtime || true; \
    useradd -G tty -l -m -s "/bin/bash" --gid 1000 --uid 1000 runtime || true; \
fi

# Ensure both users can access necessary directories
RUN chmod 777 /run/php /var/log
RUN mkdir -p /tmp/xhprof && chmod -R ugo+w /etc/php /var/lib/php /tmp/xhprof

COPY www.conf /etc/php/*/fpm/pool.d/www.conf
COPY apache-site.conf /etc/apache2/sites-enabled/apache-site.conf
COPY mpm_event.conf /etc/apache2/mods-available/mpm_event.conf

