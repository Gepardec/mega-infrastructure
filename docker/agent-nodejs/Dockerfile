# We use 3.9 because of the oc binary we use in the containers
FROM docker.io/openshift/jenkins-slave-base-centos7:v3.9

USER root

ENV NPM_CONFIG_PREFIX=/npm/.npm-global \
    PATH=/npm/node_modules/.bin/:/npm/.npm-global/bin:$PATH

# Install NodeJS
RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash - \
    && yum install -y gcc c++ make nodejs-12.5.0 \
    && npm install -g @angular/cli \
    && wget --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && yum -y install google-chrome-stable_current_x86_64.rpm \
    && rm -f google-chrome-stable_current_x86_64.rpm \
    && yum clean all -y \
    && rm -rf /var/cache/yum \
    && chown -R 1001:0 /npm \
    && chown -R 1001:0 /home/jenkins \
    && chmod -R 770 /npm \
    && chmod -R 770 /home/jenkins

USER 1001