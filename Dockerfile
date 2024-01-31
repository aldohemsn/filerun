FROM php:8.1.23-apache-bullseye

# Set environment variables for database (adjust according to your setup)
ENV FR_DB_HOST=db \
    FR_DB_PORT=3306 \
    FR_DB_NAME=filerun \
    FR_DB_USER=filerun \
    FR_DB_PASS=filerun \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_USER_ID=33 \
    APACHE_RUN_GROUP=www-data \
    APACHE_RUN_GROUP_ID=33

# Data volume for FileRun and user files
VOLUME ["/var/www/html", "/user-files"]

# Copy the application
COPY ./filerun /var/www/html

# Install necessary system packages and PHP extensions for FileRun
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpng-dev \
        mariadb-client \
    # Configure PHP extensions
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_mysql gd opcache \
    # Enable Apache mod_rewrite
    && a2enmod rewrite \
    # Cleanup to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Set the proper permissions for FileRun and user files
    && chown -R www-data:www-data /var/www/html /user-files

# Use the default PHP development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Configure Apache Document Root
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Configure Apache to serve the user-files directory
RUN echo "<Directory \"/user-files\">" > /etc/apache2/conf-available/filerun.conf \
    && echo "    Options Indexes FollowSymLinks" >> /etc/apache2/conf-available/filerun.conf \
    && echo "    AllowOverride None" >> /etc/apache2/conf-available/filerun.conf \
    && echo "    Require all granted" >> /etc/apache2/conf-available/filerun.conf \
    && echo "</Directory>" >> /etc/apache2/conf-available/filerun.conf \
    && a2enconf filerun

# Copy custom PHP configurations if you have any (not strictly necessary)
#COPY filerun.ini /usr/local/etc/php/conf.d/filerun.ini

# If you have a custom entrypoint script
#COPY entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]

# Set up the command to run Apache
CMD ["apache2-foreground"]
