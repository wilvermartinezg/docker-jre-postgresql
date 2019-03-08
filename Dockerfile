#
# example Dockerfile for https://docs.docker.com/engine/examples/postgresql_service/
#

FROM ubuntu:16.04

ADD files/jre-8u192-linux-i586.tar.gz /opt/java

ENV JRE_VERSION="jre1.8.0_192"
ENV JAVA_HOME="/opt/java/${JRE_VERSION}" HOME="/home/developer"  PATH="${PATH}:/home/developer:/opt/java/${JRE_VERSION}/bin"

RUN apt-get update \
    && apt install -y curl wget \
    && apt-get install -y sudo software-properties-common \
    && apt-get install -y nano

#Configura la interfaz grafica para 32 bits
RUN sudo dpkg --add-architecture i386 \
	&& sudo apt update \
	&& sudo apt install -y libgtk2.0-0:i386 libidn11:i386 libglu1-mesa:i386 \
	&& sudo apt install -y libxrender1 libxtst6 libxi6 \
	&& sudo apt install -y libxrender1:i386 libxtst6:i386 libxi6:i386

#Configuracion del JRE 32 bits
RUN update-alternatives --install "/usr/bin/java" "java" "/opt/java/$JRE_VERSION/bin/java" 1 \
    && update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/java/$JRE_VERSION/bin/javaws" 1 \
	&& update-alternatives --set java /opt/java/$JRE_VERSION/bin/java

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.5``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.5
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python-software-properties postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5

# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.3`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER admin WITH SUPERUSER PASSWORD 'admin';" &&\
    createdb -O admin docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
#comente este comando para iniciar manualmente el servicio de postgresql
# CMD ["/usr/lib/postgresql/9.5/bin/postgres", "-D", "/var/lib/postgresql/9.5/main", "-c", "config_file=/etc/postgresql/9.5/main/postgresql.conf"]

USER root

#configura el usuario developer
RUN echo 'Creating user: developer' \
    && mkdir -p /home/developer \
    && echo "developer:x:1000:1000:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd \
    && echo "developer:x:1000:" >> /etc/group \
    && sudo echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer \
    && sudo chmod 0440 /etc/sudoers.d/developer \
    && sudo chown developer:developer -R /home/developer \
	&& sudo chown root:root /usr/bin/sudo \
	&& chmod 4755 /usr/bin/sudo

RUN sudo chown developer:developer -R /home/developer

USER developer
WORKDIR /home/developer
