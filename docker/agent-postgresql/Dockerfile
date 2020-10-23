# Need to use jenkins slave base because of ssh issues
FROM docker.io/openshift/jenkins-slave-base-centos7:v3.9

ENV HOME=/home/jagent

USER root

RUN useradd -d /home/jagent -g 0 -u 1001 -s /usr/sbin/nologin jagent \
    && yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
    && yum install -y postgresql10 tar zip \
    && chown -R 1001:0 ${HOME}

WORKDIR ${HOME}

USER 1001
