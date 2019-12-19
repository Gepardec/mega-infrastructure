#!/bin/bash

GIT_SECRET='mega-git-ssh'
cd $(pwd)

set -u

function createMegaSecrets {
    oc create secret generic mega-secrets --from-file=filename=../mega-secrets.${STAGE}.properties
}

function deleteMegaSecrets {
    oc delete secret mega-secrets --ignore-not-found
}

function recreateMegaSecrets {
    deleteMegaSecrets
    createMegaSecrets
}

function createJenkinsSecrets {
    # Create mega secret for service and jenkins
    oc create secret generic mega-secrets --from-file=filename=../mega-secrets.${STAGE}.properties
    oc annotate secret mega-secrets jenkins.openshift.io/secret.name=mega-secrets
    oc label secret mega-secrets credential.sync.jenkins.openshift.io=true

    # Create google secret for frontend build
    oc create secret generic google-secrets --from-file=filename=../google-secrets.properties
    oc annotate secret google-secrets jenkins.openshift.io/secret.name=google-secrets
    oc label secret google-secrets credential.sync.jenkins.openshift.io=true

    # Create git ssh secret
    oc create secret generic mega-git-ssh --from-file=ssh-privatekey=../mega-dev.ssh.key --type=kubernetes.io/ssh-auth
    oc annotate secret mega-git-ssh jenkins.openshift.io/secret.name=mega-git-ssh
    oc label secret mega-git-ssh credential.sync.jenkins.openshift.io=true
    oc secrets link builder mega-git-ssh

    # Create git http secret (Necessary for multibranch plugin)
    oc create secret generic mega-git-http --from-env-file=../mega-dev-http.properties --type=kubernetes.io/basic-auth
    oc annotate secret mega-git-http jenkins.openshift.io/secret.name=mega-git-http
    oc label secret mega-git-http credential.sync.jenkins.openshift.io=true
}

function deleteJenkinsSecrets {
    oc delete secrets/mega-secrets --ignore-not-found
    oc delete secrets/google-secrets --ignore-not-found
    oc delete secrets/mega-git-ssh --ignore-not-found
    oc delete secrets/mega-git-http --ignore-not-found
}

function recreateJenkinsSecrets {
    deleteJenkinsSecrets
    createJenkinsSecrets
}

function createBuildConfigs() {
    # Binary build for backend uber jar
    oc new-build --binary=true --name=mega-zep-backend --docker-image=docker.io/fabric8/s2i-java:3.0-java11
    oc set triggers bc/mega-zep-backend --remove-all

    # Binary build for frontend html content
    oc new-build httpd:2.4 --binary=true --name=mega-zep-frontend
    oc set triggers bc/mega-zep-frontend --remove-all

    # Quarkus Build Agent
    oc new-build https://github.com/Gepardec/mega-infrastructure.git#master --name=quarkus-build-agent --context-dir=docker/agent-quarkus --source-secret=${GIT_SECRET}
    oc set triggers bc/quarkus-build-agent --remove-all

    # Nodejs Build Agent
    oc new-build https://github.com/Gepardec/mega-infrastructure.git#master --name=nodejs-build-agent --context-dir=docker/agent-nodejs --source-secret=${GIT_SECRET}
    oc set triggers bc/nodejs-build-agent --remove-all
}

function deleteBuildConfigs() {
    oc delete bc/mega-zep-backend --ignore-not-found
    oc delete bc/mega-zep-frontend --ignore-not-found
    oc delete bc/quarkus-build-agent --ignore-not-found
    oc delete bc/nodejs-build-agent --ignore-not-found
}

function recreateBuildConfigs() {
    deleteBuildConfigs
    createBuildConfigs
}

function createJenkins {
    oc process -f jenkins/jenkins-bc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc apply -f -
    oc process -f jenkins/jenkins.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc apply -f -
    oc create -f  jenkins/maven-pvc.yaml
}

function deleteJenkins {
    oc process -f jenkins/jenkins-bc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
    oc process -f jenkins/jenkins.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
    oc delete -f  jenkins/maven-pvc.yaml
}

function recreateJenkins {
    deleteJenkins
    createJenkins
}

${1}