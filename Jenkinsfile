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
    }
}
