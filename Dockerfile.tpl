# ################################################################
# DESC: Docker file to create Logstash container.
# ################################################################

FROM alpine:latest

# Setup environment
ENV LS_VERSION %%VERSION%%
ENV LS_HOME /opt/logstash
ENV LS_CFG_DIR /etc/logstash
ENV LS_USER logstash
ENV LS_GROUP logstash

ENV PKG_URL "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64"

ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 45
ENV JAVA_VERSION_BUILD 14
ENV JAVA_BASE /usr/local/java
ENV JAVA_HOME $JAVA_BASE/jdk

# Install requirements and Logstash
RUN apk --update add \
      curl \
      python \
      py-pip \
      bash && \
    curl --silent --insecure --location --remote-name "${PKG_URL}/glibc-2.21-r2.apk" &&\
    curl --silent --insecure --location --remote-name "${PKG_URL}/glibc-bin-2.21-r2.apk" &&\
    apk add --allow-untrusted \
      glibc-2.21-r2.apk \
      glibc-bin-2.21-r2.apk &&\
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib &&\
    mkdir -p ${JAVA_BASE} ${LS_CFG_DIR}/ssl ${LS_CFG_DIR}/conf.d  /opt &&\
    curl --silent --insecure --location --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz | tar zxf - -C $JAVA_BASE &&\
    ln -s $JAVA_BASE/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME} &&\
    curl --silent --insecure --location https://download.elasticsearch.org/logstash/logstash/logstash-${LS_VERSION}.tar.gz | tar zxf - -C /opt &&\
    ln -s /opt/logstash-${LS_VERSION} ${LS_HOME} &&\
    addgroup ${LS_GROUP} &&\
    adduser -h ${LS_HOME} -D -s /bin/bash -G ${LS_GROUP} ${LS_USER} &&\
    chown -R ${LS_USER}:${LS_GROUP} ${LS_HOME}/ ${LS_CFG_DIR}

# Configure environment
COPY src/ /

# Listen for defaults: 5000/tcp:udp (syslog), 5002/tcp (logstash-forwarder), 5004/tcp (journal), 5006/udp (Logspout), 5200/tcp (log4j)
EXPOSE 5000 5002 5004 5006 5200

# Expose volumes
VOLUME ["${LS_CFG_DIR}"]

ENTRYPOINT ["/usr/local/bin/logstash.sh"]
CMD [""]
