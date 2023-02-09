FROM adminer:4.8.1


ENV LD_LIBRARY_PATH /usr/local/instantclient_21_1
ENV ORACLE_HOME /usr/local/instantclient_21_1

USER root
RUN apk update && apk upgrade --available \
 && apk add --no-cache bash autoconf build-base composer libaio libnsl libc6-compat busybox-extras

ADD tmp/. /tmp/.


RUN unzip -d /usr/local/ /tmp/instantclient-basic-linux.x64-21.1.0.0.0.zip
RUN unzip -d /usr/local/ /tmp/instantclient-sdk-linux.x64-21.1.0.0.0.zip
RUN unzip -d /usr/local/ /tmp/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip

RUN ln -s /usr/lib/libnsl.so.2 /usr/lib/libnsl.so.1
RUN ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2
RUN ln -s /lib64/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2
RUN pear upgrade --force && pecl upgrade

ADD tmp/instantclient.ini /etc/php.d/instantclient.ini

RUN docker-php-ext-configure oci8 --with-oci8=instantclient,$ORACLE_HOME
RUN docker-php-ext-install oci8
