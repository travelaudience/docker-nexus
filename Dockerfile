FROM alpine:3.12

LABEL maintainer devops@travelaudience.com

# User settings for nexus user
ARG UID=1000
ARG GID=1000
ARG USER=nexus

# java
ENV JAVA_HOME=/usr/lib/jvm/default-jvm/jre

# nexus latest binary release link
# https://help.sonatype.com/repomanager3/download/download-archives---repository-manager-3

# nexus
ENV NEXUS_VERSION "3.29.2-02"
ENV NEXUS_DOWNLOAD_URL "https://download.sonatype.com/nexus/3"
ENV NEXUS_TARBALL_URL "${NEXUS_DOWNLOAD_URL}/nexus-${NEXUS_VERSION}-unix.tar.gz"
ENV NEXUS_TARBALL_ASC_URL "${NEXUS_DOWNLOAD_URL}/nexus-${NEXUS_VERSION}-unix.tar.gz.asc"
ENV GPG_KEY 0374CF2E8DD1BDFD

ENV SONATYPE_DIR /opt/sonatype
ENV NEXUS_HOME "${SONATYPE_DIR}/nexus"
ENV NEXUS_DATA /nexus-data
ENV NEXUS_CONTEXT ''
ENV SONATYPE_WORK ${SONATYPE_DIR}/sonatype-work
ENV HOME ${NEXUS_HOME}

# Install prerequisites
RUN apk add --no-cache --update bash ca-certificates runit su-exec util-linux openjdk8-jre

# Install nexus
RUN apk add --no-cache -t .build-deps wget gnupg openssl \
  && cd /tmp \
  && echo "===> Installing Nexus ${NEXUS_VERSION}..." \
  && wget -O nexus.tar.gz $NEXUS_TARBALL_URL; \
  wget -O nexus.tar.gz.asc $NEXUS_TARBALL_ASC_URL; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys $GPG_KEY; \
    gpg --batch --verify nexus.tar.gz.asc nexus.tar.gz; \
    rm -r $GNUPGHOME nexus.tar.gz.asc; \
  tar -xf nexus.tar.gz \
  && mkdir -p $SONATYPE_DIR \
  && mv nexus-$NEXUS_VERSION $NEXUS_HOME \
  && cd $NEXUS_HOME \
  && ls -las \
  && adduser -h $NEXUS_DATA -DH -s /sbin/nologin ${USER} \
  && chown -R ${USER}:0 $NEXUS_HOME \ # for OpenShift restricted SCC compatibility
  && rm -rf /tmp/* /var/cache/apk/* \
  && apk del --purge .build-deps

# Configure nexus
RUN sed \
    -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' \
    -i ${NEXUS_HOME}/etc/nexus-default.properties \
  && sed \
    -e '/^-Xms/d' \
    -e '/^-Xmx/d' \
    -i ${NEXUS_HOME}/bin/nexus.vmoptions

RUN mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp ${SONATYPE_WORK} \
  && ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3 \
  && chown -R ${USER}:0 ${NEXUS_DATA} ${NEXUS_HOME} /etc/service/nexus /opt/sonatype \ # to run as nonroot and for OpenShift restricted SCC compatibility
  && chmod -R g=u ${NEXUS_HOME} ${NEXUS_DATA} /etc/service/nexus /opt/sonatype \ # to run as nonroot and for OpenShift restricted SCC compatibility

# Update logback configuration to store 30 days logs rather than 90 days default
RUN sed -i -e 's|<maxHistory>90</maxHistory>|<maxHistory>30</maxHistory>|g' ${NEXUS_HOME}/etc/logback/logback*.xml

# Important to specify nonroot user and by the uid for compatibility with K8s PSPs and OpenShift SCCs
USER ${UID}

VOLUME ${NEXUS_DATA}

EXPOSE 8081

WORKDIR ${NEXUS_HOME}

ENV INSTALL4J_ADD_VM_PARAMS="-Xms1200m -Xmx1200m"

CMD ["/opt/sonatype/nexus/bin/nexus", "run"]
