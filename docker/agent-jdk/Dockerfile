# Need to use jenkins slave base because of ssh issues
FROM openshift/jenkins-slave-base-centos7:v3.9

ENV HOME=/home/jagent \
    MAVEN_HOME=/maven \
    M2_HOME=/maven  \
    PATH=/openjdk-11/bin:/maven/bin:${PATH} \
    JAVA_HOME=/openjdk-11

USER root

ADD docker-entrypoint.sh /

RUN useradd -d /home/jagent -g 0 -u 1001 -s /usr/sbin/nologin jagent \
    && mkdir -p ${MAVEN_HOME} ${JAVA_HOME} \
    && curl -L --silent --show-error --fail https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz \
         | tar --strip-components=1 -zx -C ${JAVA_HOME} \
    && curl -L --silent --show-error --fail https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
         | tar --strip-components=1 -zx -C /maven \
    && chown -R 1001:0 /docker-entrypoint.sh ${HOME} ${MAVEN_HOME} ${JAVA_HOME} \
    && chmod -R 770 /docker-entrypoint.sh ${HOME} ${MAVEN_HOME} ${JAVA_HOME}

WORKDIR ${HOME}

USER 1001
