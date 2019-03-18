properties([pipelineTriggers([cron('0 * * * *')])])

library(
    identifier: 'pipeline-lib@4.3.4',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

def image

node('infrastructure') {
    ansiColor('xterm') {
        scos.doCheckoutStage()

        stage('Build') {
            image = docker.build("scos_system_test:${env.GIT_COMMIT_HASH}")
        }

        stage('Test') {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_jenkins_user', variable: 'AWS_ACCESS_KEY_ID']]) {
                sh('''
                export HOST_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
                mix local.hex --force
                mix local.rebar --force
                mix deps.get
                mix test
                ''')
            }
        }
    }
}
