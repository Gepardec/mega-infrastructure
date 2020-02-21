# On Jenkins git via ssh says 'no user for uid ....' so only http works for now
FROM library/openjdk:11-jdk-slim

ENV HOME=/home/jagent \
    MAVEN_HOME=/maven \
    M2_HOME=/maven  \
    PATH=/ocp:/maven/bin:${PATH}

USER root

WORKDIR ${HOME}

ADD docker-entrypoint.sh /

RUN useradd -d /home/jagent -g 0 -u 1001 -s /usr/sbin/nologin jagent \
    && apt-get update \
    && apt-get install -y curl git \
    && apt-get autoclean \
    && apt-get clean \
    && mkdir -p /maven /ocp \
    && curl -L --silent --show-error --fail https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz \
         | tar --strip-components=1 -zx -C /ocp \
    && curl -L --silent --show-error --fail https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz \
         | tar --strip-components=1 -zx -C /maven \
    && chown -R 1001:0 ${HOME} /docker-entrypoint.sh ${MAVEN_HOME} ${JAVA_HOME} /ocp \
    && chmod -R 777 ${HOME} /docker-entrypoint.sh ${MAVEN_HOME} ${JAVA_HOME} /ocp

WORKDIR ${HOME}

USER 1001 