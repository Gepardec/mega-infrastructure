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
    oc delete secrets/mega-git-ssh --ignore-not-found
    oc delete secrets/mega-git-http --ignore-not-found
}

function recreateJenkinsSecrets {
    deleteJenkinsSecrets
    createJenkinsSecrets
}

function createBuildConfigs() {
    # Binary build for backend uber jar
    oc new-build --binary=true --name=mega-zep-backend --docker-image=docker.io/fabric8/s2i-java:latest-java11
    oc set triggers bc/mega-zep-backend --remove-all

    # Binary build for frontend html content
    oc new-build httpd:2.4 --binary=true --name=mega-zep-frontend
    oc set triggers bc/mega-zep-frontend --remove-all

    # Quarkus Build Agent
    oc new-build https://github.com/Gepardec/mega-infrastructure.git#master --name=quarkus-build-agent --context-dir=docker/agent-quarkus --source-secret=${GIT_SECRET}

    # Nodejs Build Agent
    oc new-build https://github.com/Gepardec/mega-infrastructure.git#master --name=nodejs-build-agent --context-dir=docker/agent-nodejs --source-secret=${GIT_SECRET}
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
}

function deleteJenkins {
    oc process -f jenkins/jenkins-bc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
    oc process -f jenkins/jenkins.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
}

function recreateJenkins {
    deleteJenkins
    createJenkins
}

function createJenkinsPvc {
    oc process -f jenkins/jenkins-pvc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc apply -f -
}

function deleteJenkinsPvc {
    oc process -f jenkins/jenkins-pvc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
}

function recreateJenkinsPvc {
    deleteJenkinsPvc
    createJenkinsPvc
}


function createMavenPvc {
    oc process -f  jenkins/maven-pvc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc apply -f -
}

function deleteMavenPvc {
    oc process -f  jenkins/maven-pvc.yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -
}

function recreateMavenPvc {
    deleteMavenPvc
    createMavenPvc
}

${1}