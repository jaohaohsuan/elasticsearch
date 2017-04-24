podTemplate(
    label: 'es-build',
    containers: [
        containerTemplate(name: 'jnlp', image: 'henryrao/jnlp-slave', args: '${computer.jnlpmac} ${computer.name}', alwaysPullImage: true)
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
    ]) {

    node('es-build') {
        def image
        stage('git clone') {
            checkout scm
        }
        stage('build image') {
            image = docker.build('henryrao/elasticsearch:$BRANCH_NAME', '--pull .')
        }
        stage('testing') {
            image.inside {
                parallel 'test-1': {
                    sh 'id'
                }, 'test-2': {
                    sh 'echo $PATH'
                }, functionality: {
                    sh '''
                    ls -al /opt/elasticsearch
                    elasticsearch --help
                    '''
                },
                failFast: true
            }
        }
        stage('push image') {
            withDockerRegistry(url: 'https://index.docker.io/v1/', credentialsId: 'docker-login') {
                parallel versioned: {
                    image.push()
                }, latest: {
                },
                failFast: false
            }
        }
    }
}
