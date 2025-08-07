ARG php_version=8.3

# CraftCMS dependencies
FROM ghcr.io/craftcms/image:${php_version}

ARG dest_env=staging

USER root

RUN apt-get update --fix-missing
RUN apt-get install -y curl \
    default-mysql-client \
    letsencrypt \
    nano \
    sudo

COPY entrypoint.sh /etc
RUN chmod u+x /etc/entrypoint.sh

# Start and enable SSH
COPY sshd_config /etc/ssh/
RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd

RUN ssh-keygen -A
# RUN addgroup sudo
RUN adduser www-data sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir /run/sshd

# copy the files from the host to the container that we need
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/php-fpm/php-fpm.conf /etc/php-fpm.conf
COPY etc/php-fpm/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf
COPY etc/php.d/60-craftcms.ini /etc/php/8.3/fpm/conf.d/60-craftcms.ini

# set the sockets and pid files to be writable by the appuser
RUN chown -R www-data:www-data /var/lib/nginx && touch /run/nginx.pid && chown -R www-data:www-data /run/nginx.pid
RUN touch /run/php/php8.3-fpm.sock && chown -R www-data:www-data /run/php/php8.3-fpm.sock

COPY --chown=www-data:www-data etc/supervisor/conf.d/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY --chown=www-data:www-data etc/supervisord.d/ /etc/supervisord.d

# Install CraftCMS code
RUN chown -R www-data:www-data /var/www
COPY --chown=www-data:www-data ./ /var/www/html
WORKDIR /var/www/html
RUN cp .env.$dest_env .env
RUN rm .env.*

# Install Composer
USER www-data
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev -o

#USER root

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["sh", "/etc/entrypoint.sh"]