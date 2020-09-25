#!/bin/bash

cd $(pwd)

set -u

function createMegaSecrets {
    oc create secret generic mega --from-file=filename=../mega-secrets.${STAGE}.properties
    oc create secret generic mega-zep-db --from-env-file=../mega-zep-db.${STAGE}.properties
}

function deleteMegaSecrets {
    oc delete secret mega --ignore-not-found
    oc delete secret mega-zep-db --ignore-not-found
}

function recreateMegaSecrets {
    deleteMegaSecrets
    createMegaSecrets
}

function createJenkinsSecrets {
    # Create git http secret (Necessary for multibranch plugin)
    # DON#T RENAME IS USED BY BUILD CONFIGS AS WELL
    oc create secret generic github-http --from-env-file=../secrets/jenkins/jenkins-git-http.properties --type=kubernetes.io/basic-auth
    oc annotate secret github-http jenkins.openshift.io/secret.name=github-http
    oc label secret github-http credential.sync.jenkins.openshift.io=true

    # Create mega secret for service and jenkins
    oc create secret generic jenkins-mega --from-file=filename=../secrets/jenkins/jenkins-mega.properties
    oc annotate secret jenkins-mega jenkins.openshift.io/secret.name=jenkins-mega
    oc label secret jenkins-mega credential.sync.jenkins.openshift.io=true

    # Create git http secret (Necessary for multibranch plugin)
    oc create secret generic jenkins-dockerhub --from-env-file=../secrets/jenkins/jenkins-dockerhub.properties --type=kubernetes.io/basic-auth
    oc annotate secret jenkins-dockerhub jenkins.openshift.io/secret.name=dockerhub
    oc label secret jenkins-dockerhub credential.sync.jenkins.openshift.io=true

    # Create jenkins mega db dev secret
    oc create secret generic jenkins-mega-db-dev --from-env-file=../secrets/jenkins/jenkins-mega-db-dev.properties --type=kubernetes.io/basic-auth
    oc annotate secret jenkins-mega-db-dev jenkins.openshift.io/secret.name=mega-db-dev
    oc label secret jenkins-mega-db-dev credential.sync.jenkins.openshift.io=true

    # Create jenkins mega db test secret
    oc create secret generic jenkins-mega-db-test --from-env-file=../secrets/jenkins/jenkins-mega-db-test.properties --type=kubernetes.io/basic-auth
    oc annotate secret jenkins-mega-db-test jenkins.openshift.io/secret.name=mega-db-test
    oc label secret jenkins-mega-db-test credential.sync.jenkins.openshift.io=true

    # Create jenkins mega db prod secret
    oc create secret generic jenkins-mega-db-prod --from-env-file=../secrets/jenkins/jenkins-mega-db-prod.properties --type=kubernetes.io/basic-auth
    oc annotate secret jenkins-mega-db-prod jenkins.openshift.io/secret.name=mega-db-prod
    oc label secret jenkins-mega-db-prod credential.sync.jenkins.openshift.io=true

    # Create jenkins-config-secret
    oc create configmap jenkins-config --from-file=jenkins-config.yaml=../config/jenkins/jenkins-config.yaml
    
    # Create jenkins-config-secret
    oc create secret generic jenkins --from-env-file=../secrets/jenkins/jenkins-secrets.properties --type=kubernetes.io/opaque
}

function deleteJenkinsSecrets {
    oc delete configmap/jenkins-config --ignore-not-found

    oc delete secrets/github-http --ignore-not-found
    oc delete secrets/jenkins-mega --ignore-not-found
    oc delete secrets/jenkins-dockerhub --ignore-not-found
    oc delete secrets/jenkins-mega-db-dev --ignore-not-found
    oc delete secrets/jenkins-mega-db-test --ignore-not-found
    oc delete secrets/jenkins-mega-db-prod --ignore-not-found
    oc delete secrets/jenkins --ignore-not-found
}

function recreateJenkinsSecrets {
    deleteJenkinsSecrets
    createJenkinsSecrets
}

function createBuildConfigs() {
    oc process -f jenkins/jenkins-agent-bc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc apply -f -

    # Binary build for backend uber jar
    oc new-build --binary=true --name=mega-zep-backend --docker-image=docker.io/fabric8/s2i-java:latest-java11
    oc set triggers bc/mega-zep-backend --remove-all

    # Binary build for frontend html content
    oc new-build httpd:2.4 --binary=true --name=mega-zep-frontend
    oc set triggers bc/mega-zep-frontend --remove-all
}

function deleteBuildConfigs() {
    oc process -f jenkins/jenkins-agent-bc.yaml -o yaml --param-file=jenkins/jenkins.properties --ignore-unknown-parameters=true | oc delete -f -

    oc delete bc/mega-zep-backend --ignore-not-found
    oc delete bc/mega-zep-frontend --ignore-not-found
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

function createMegaDbIs {
     oc create --filename mega-zep-db/is.json
}

function deleteMegaDbIs {
     oc delete --filename mega-zep-db/is.json \
                --ignore-not-found
}

function recreateMegaDbIs {
  deleteMegaDbIs
  createMegaDbIs
}

function createMegaDbPvc {
     oc process --filename mega-zep-db/pvc.yml \
                --param-file=mega-zep-db/parameters.${STAGE}.properties \
                --ignore-unknown-parameters=true \
     | oc create --filename -
}

function deleteMegaDbPvc {
     oc process --filename mega-zep-db/pvc.yml \
                --param-file=mega-zep-db/parameters.${STAGE}.properties \
                --ignore-unknown-parameters=true \
     | oc delete --filename - \
                 --ignore-not-found
}

function recreateMegaDbPvc {
  deleteMegaDbPvc
  createMegaDbPvc
}

function createMegaDb {
     oc process --filename mega-zep-db/template.yml \
                --param-file=mega-zep-db/parameters.${STAGE}.properties \
                --ignore-unknown-parameters=true \
     | oc create --filename -
}

function deleteMegaDb {
     oc process --filename mega-zep-db/template.yml \
                --param-file=mega-zep-db/parameters.${STAGE}.properties \
                --ignore-unknown-parameters=true \
     | oc delete --filename - \
                 --ignore-not-found
}

function recreateMegaDb {
  deleteMegaDb
  createMegaDb
}

function recreateMavenPvc {
    deleteMavenPvc
    createMavenPvc
}

${1}