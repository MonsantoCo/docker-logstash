# Docker file to create Logstash container.
FROM cgswong/java:openjre8

# Setup environment
ENV LS_VERSION %%VERSION%%
ENV LS_HOME /opt/logstash
ENV LS_CFG_DIR /etc/logstash
ENV LS_USER logstash
ENV LS_GROUP logstash

# Install requirements and Logstash
RUN apk --update add \
      curl \
      python \
      py-pip \
      bash &&\
    mkdir -p \
      ${LS_CFG_DIR}/ssl \
      ${LS_CFG_DIR}/conf.d  \
      /opt &&\
    curl -sSL --insecure --location https://download.elasticsearch.org/logstash/logstash/logstash-${LS_VERSION}.tar.gz | tar zxf - -C /opt &&\
    ln -s /opt/logstash-${LS_VERSION} ${LS_HOME} &&\
    addgroup ${LS_GROUP} &&\
    adduser -h ${LS_HOME} -D -s /bin/bash -G ${LS_GROUP} ${LS_USER} &&\
    chown -R ${LS_USER}:${LS_GROUP} ${LS_HOME}/ ${LS_CFG_DIR}

# Configure environment
COPY src/ /

# Listen for defaults: 5000/tcp:udp (syslog), 5002/tcp (logstash-forwarder), 5004/tcp (journald), 5006/udp (Logspout), 5200/tcp (log4j)
EXPOSE 5000 5002 5004 5006 5200

# Expose volumes
VOLUME ["${LS_CFG_DIR}"]

ENTRYPOINT ["/usr/local/bin/logstash.sh"]
CMD [""]
