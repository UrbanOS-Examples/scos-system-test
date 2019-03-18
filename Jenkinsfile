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

        stage('Test') {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_jenkins_user', variable: 'AWS_ACCESS_KEY_ID']]) {
                image = docker.build("scos_system_test:${env.GIT_COMMIT_HASH}", '-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY .')
            }
        }
    }
}
