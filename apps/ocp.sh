#!/bin/bash

GIT_SECRET='mega-git-ssh'

cd $(pwd)

set -u

function createSecrets {
    # Create mega secret for service and jenkins
    oc create secret generic mega-secrets --from-file=filename=mega-secrets.properties
    oc annotate secret mega-secrets jenkins.openshift.io/secret.name=mega-secrets
    oc label secret mega-secrets credential.sync.jenkins.openshift.io=true

    # Create google secret for frontend build
    oc create secret generic google-secrets --from-file=filename=google-secrets.properties
    oc annotate secret google-secrets jenkins.openshift.io/secret.name=google-secrets
    oc label secret google-secrets credential.sync.jenkins.openshift.io=true

    # Create git ssh secret
    oc create secret generic mega-git-ssh --from-file=ssh-privatekey=mega-dev.ssh.key --type=kubernetes.io/ssh-auth -n 57-mega-dev
    oc annotate secret mega-git-ssh jenkins.openshift.io/secret.name=mega-git-ssh
    oc label secret mega-git-ssh credential.sync.jenkins.openshift.io=true
    oc secrets link builder mega-git-ssh
}

function deleteSecrets {
    oc delete secrets/mega-secrets
    oc delete secrets/google-secrets
    oc delete secrets/mega-git-ssh
}

function recreateSecrets{
    deleteSecret
    createSecrets
}

function createBuildConfigs() {
    # Binary build for backend uber jar
    oc new-build --binary=true --name=mega-zep-backend --docker-image=docker.io/fabric8/s2i-java:3.0-java11
    oc set triggers bc/mega-zep-backend --remove-all

    # Binary build for frontend html content
    oc new-build httpd:2.4 --binary=true --name=mega-zep-frontend
    oc set triggers bc/mega-zep-frontend --remove-all

    # Quarkus Build Agent
    oc new-build git@github.com:Gepardec/mega-infrastructure.git#master --name=quarkus-build-agent --context-dir=docker/agent-quarkus --source-secret=${GIT_SECRET}
    oc set triggers bc/quarkus-build-agent --remove-all

    # Nodejs Build Agent
    oc new-build git@github.com:Gepardec/mega-infrastructure.git#master --name=nodejs-build-agent --context-dir=docker/agent-nodejs --source-secret=${GIT_SECRET}
    oc set triggers bc/nodejs-build-agent --remove-all
}

function deleteBuildConfigs() {
    oc delete bc/mega-zep-backend
    oc delete bc/mega-zep-frontend
    oc delete bc/quarkus-build-agent
    oc delete bc/nodejs-build-agent
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