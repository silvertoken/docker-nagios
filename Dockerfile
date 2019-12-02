ARG FROM_IMAGE_NAME=alpine:latest
FROM $FROM_IMAGE_NAME as mybase

# COPY qemu-arm-static /usr/bin/

# docker images --quiet --filter=dangling=true | xargs --no-run-if-empty docker rmi -f &&  time docker build -t manios/nagios:bu .
# docker run -p 8080:80 -it --rm --name agios manios/nagios:bu /bin/sh

# docker run --rm -u $(id -u):$(id -g) -v $PWD:/data vimagick/youtube-dl --limit-rate 150K http://streamcloud.eu/vtc949crkb3g/GR_God_Willing_2015.mp4.html

# docker run --rm -u $(id -u):$(id -g) -v $PWD:/data vimagick/youtube-dl -F

ENV NAGIOS_HOME=/opt/nagios \
    NAGIOS_USER=nagios \
    NAGIOS_GROUP=nagios \
    NAGIOS_CMDUSER=nagios \
    NAGIOS_CMDGROUP=nagios \
    NAGIOS_TIMEZONE=UTC \
    NAGIOS_FQDN=nagios.example.com \
    NAGIOSADMIN_USER=nagiosadmin \
    NAGIOSADMIN_PASS=nagios \
    NAGIOS_BRANCH=nagios-4.4.5 \
    NAGIOS_PLUGINS_BRANCH=release-2.2.1 \
    NRPE_BRANCH=nrpe-3.2.1 \
    APACHE_LOCK_DIR=/var/run \
    APACHE_LOG_DIR=/var/log/apache2

RUN addgroup -S ${NAGIOS_GROUP} && \
    adduser  -S ${NAGIOS_USER} -G ${NAGIOS_CMDGROUP} && \
    apk update && \
    apk add --no-cache git curl unzip apache2 apache2-utils rsyslog \
                        php7 php7-gd php7-cli runit parallel ssmtp \
                        libltdl libintl openssl-dev php7-apache2 procps && \
    wget https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 && \
    mv gosu-amd64 /bin/gosu && \
    chmod 755 /bin/gosu && \
    chmod +s /bin/gosu && \
    addgroup -S apache ${NAGIOS_CMDGROUP}
   
    
### ================================== ###
###   STAGE 2 COMPILE NAGIOS SOURCES   ###
### ================================== ###

FROM manios/nagios-src-builder:latest as sourcebuilder

# Print something to denote that the sourcebuilder image has been downloaded
RUN echo "Downloaded manios/nagios-src-builder image"

### ========================== ###
### START OF ACTUAL DOCKERFILE ###
### ========================== ###

FROM mybase

MAINTAINER Christos Manios <maniopaido@gmail.com>

LABEL name="Nagios" \
      version="4.4.5" \
      homepage="https://www.nagios.com/" \
      maintainer="Christos Manios <maniopaido@gmail.com>" \
      build="1"


RUN mkdir -p ${NAGIOS_HOME}  && \
    mkdir -p /orig/apache2
    
WORKDIR ${NAGIOS_HOME}
COPY --from=sourcebuilder ${NAGIOS_HOME} ${NAGIOS_HOME}

COPY --from=sourcebuilder /orig /orig

ADD overlay/ /

# Make 
RUN chmod +x /usr/local/bin/start_nagios                 \
            /etc/sv/apache/run                           \
            /etc/sv/nagios/run                           \
            /etc/sv/rsyslog/run                       && \
            rm -rf /etc/sv/getty-5                    && \
                                                         \
            : '# enable all runit services'           && \
            ln -s /etc/sv/* /etc/service              && \
                                                         \
            : '# Copy initial settings files'         && \
            chown -R nagios:nagios ${NAGIOS_HOME}     && \
            : '# Create special dirs'                 && \
            (mkdir /run/apache2 || true)              && \
            mkdir -p /var/spool/rsyslog               && \
            : '# Copy Apache configuration'           && \
            cp -Rp /orig/apache2/* /etc/apache2       && \
            : '# Convert files to Unix format'        && \
            dos2unix /etc/rsyslog.conf                && \
            dos2unix /usr/local/bin/start_nagios      && \
            dos2unix /etc/sv/**/run                   && \
            dos2unix /etc/ssmtp/ssmtp.conf
            
            
EXPOSE 80

VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "/var/log/apache2" "/opt/Custom-Nagios-Plugins"

CMD [ "/usr/local/bin/start_nagios" ]


# docker build -t manios/nagios:latest .
# docker run -it --rm -p 8080:80 manios/nagios:latest
# docker run -it --name agios -p 8080:80 manios/nagios:latest

# sed -i "s/^ *ScriptAlias.*$/ScriptAlias \\/cgi-bin\\/ \"${NAGIOS_HOME}\"\\/sbin\\//g" httpd.conf 

#    ScriptAlias /cgi-bin /home/bob/

# NAGIOS_HOME='/opt/nagios' && \
# sed -i "s|^ *ScriptAlias.*$|ScriptAlias /cgi-bin $NAGIOS_HOME/sbin|g" sbob.conf
