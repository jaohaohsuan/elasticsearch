podTemplate(
    label: 'es-build',
    containers: [
        containerTemplate(name: 'jnlp', image: 'henryrao/jnlp-slave', args: '${computer.jnlpmac} ${computer.name}', alwaysPullImage: true)
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'), 
        hostPathVolume(mountPath: '/root/.kube/config', hostPath: '/root/.kube/config'),
        persistentVolumeClaim(claimName: 'helm-repository', mountPath: '/var/helm/repo', readOnly: false)
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
            stage('system testing') {
                image.inside('--privileged -e ES_HEAP_SIZE=128m') {
                  sh 'run.sh elasticsearch -p /tmp/es.pid -Dbootstrap.mlockall=true &'
                  sh 'apk --no-cache add curl'
                  sh '''
                  until curl 127.0.0.1:9200?pretty
                  do
                    sleep 5
                  done
                  '''
                  sh 'kill -9 `cat /tmp/es.pid`'

                  // After turning off file logging '/opt/elasticsearch/logs' should be empty.
                  sh '[ ! "$(ls -A /opt/elasticsearch/logs)" ] && echo "file logging off"'
                }
            }
            stage('integration testing') {
                image.withRun('--privileged -e ES_HEAP_SIZE=64m', 'run.sh elasticsearch -Dbootstrap.mlockall=true -Dhttp.cors.enabled=true -Dhttp.cors.allow-origin=* -Dnetwork.host=0.0.0.0') { c ->
                  def server = "http://${containerIP(c)}:9200"
                  timeout(time: 60, unit: 'SECONDS') {
                      waitUntil {
                          def r = sh script: "curl -i ${server}", returnStatus: true
                          return (r == 0)
                      }
                  }
                  parallel 'index-doc': {
                    httpRequest contentType: 'APPLICATION_JSON', httpMode: 'PUT', requestBody: '''{
                          "title": "My first blog entry",
                          "text":  "Just trying this out...",
                          "date":  "2014/01/01"
                        }''', responseHandle: 'NONE', url: "${server}/website/blog/123", validResponseCodes: '201'
                  }, 'node-check': {
                    httpRequest url: "${server}/_cat/health?h=node.total", validResponseCodes: '200', validResponseContent: '1'
                  },failFast: false
                }
            }
            stage('release') {
                parallel 'docker-hub': {
                  withDockerRegistry(url: 'https://index.docker.io/v1/', credentialsId: 'docker-login') {
                    image.push()
                  }
                }, 'helm-repo': {
                  docker.image('henryrao/helm:2.3.1').inside('') { c ->
                      sh '''
                      # packaging
                      helm package --destination /var/helm/repo elasticsearch
                      helm repo index --url https://grandsys.github.io/helm-repository/ --merge /var/helm/repo/index.yaml /var/helm/repo
                      '''
                  }
                }, failFast: false
            }
        }
    }
}

def containerIP(container) {
    return sh(script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${container.id}", returnStdout: true).trim()
}
