FROM docker.io/openshift/jenkins-slave-base-centos7:v3.11

ENV PATH=$PATH:/maven/bin
ENV MAVEN_HOME=/maven \
    M2_HOME=/maven

ARG JAVA_VERSION='11.0.2'
ARG MAVEN_VERSION='3.6.2'

USER root 

RUN mkdir /java /maven \
    && curl -L --silent --show-error --fail https://download.java.net/java/GA/jdk11/9/GPL/openjdk-${JAVA_VERSION}_linux-x64_bin.tar.gz \
        | tar --strip-components=1 -zx -C /java \
    && curl -L --silent --show-error --fail https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
         | tar --strip-components=1 -zx -C /maven \
    && chown -R 1001:0 /home/jenkins /java /maven \
    && chmod -R 770 /home/jenkins /java /maven

USER 1001