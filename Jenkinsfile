library(
    identifier: 'pipeline-lib@4.3.4',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

schedule = scos.changeset.isMaster ? 'H * * * *' : ''
properties([pipelineTriggers([cron(schedule)])])

def image

node('infrastructure') {
    ansiColor('xterm') {
        scos.doCheckoutStage()

        stage('Build') {
            withCredentials([string(credentialsId: 'hex-read', variable: 'HEX_TOKEN')]) {
                image = docker.build("scos_system_test:${env.GIT_COMMIT_HASH}", '--build-arg HEX_TOKEN=$HEX_TOKEN .')
            }
        }

        stage('Test') {
            withCredentials([string(credentialsId: 'hex-read', variable: 'HEX_TOKEN'), [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_jenkins_user', variable: 'AWS_ACCESS_KEY_ID']]) {
                sh('''
                export HOST_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
                mix local.hex --force
                mix local.rebar --force
                mix hex.organization auth smartcolumbus_os --key ${HEX_TOKEN}
                mix deps.get
                MIX_ENV=system mix test
                ''')
            }
        }
    }
}
