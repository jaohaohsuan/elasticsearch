podTemplate(
    label: 'es-build',
    containers: [
        containerTemplate(name: 'jnlp', image: 'henryrao/jnlp-slave', args: '${computer.jnlpmac} ${computer.name}', alwaysPullImage: true)
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
    ]) {

    node('es-build') {
        ansiColor('xterm') {
            def image
            stage('git clone') {
                checkout scm
            }
            stage('build image') {
                image = docker.build("henryrao/elasticsearch:${env.BRANCH_NAME}", '--pull .')
            }
            stage('testing') {
                docker.image("henryrao/elasticsearch:${env.BRANCH_NAME}").inside('--privileged -e ES_HEAP_SIZE=256m') {
                  sh 'run.sh elasticsearch -p /tmp/es.pid -Dbootstrap.mlockall=true &'
                  sh 'apk --no-cache add curl'
                  sh '''
                  until curl 127.0.0.1:9200?pretty
                  do
                    sleep 5
                  done
                  '''
                  sh 'kill -9 `cat /tmp/es.pid`'
                  sh 'cat /opt/elasticsearch/logs/elasticsearch.log'
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
}
