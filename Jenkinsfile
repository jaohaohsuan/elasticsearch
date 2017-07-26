podTemplate(
    label: 'es-build', containers: [
      containerTemplate(name: 'jnlp', image: env.JNLP_SLAVE_IMAGE, args: '${computer.jnlpmac} ${computer.name}', alwaysPullImage: true),
      containerTemplate(name: 'kube', image: "${env.PRIVATE_REGISTRY}/library/kubectl:v1.7.2", ttyEnabled: true, command: 'cat'),
      containerTemplate(name: 'helm', image: 'henryrao/helm:2.3.1', ttyEnabled: true, command: 'cat'),
      containerTemplate(name: 'dind', image: 'docker:stable-dind', privileged: true, ttyEnabled: true, command: 'dockerd', args: '--host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=vfs')
    ],
    volumes: [
        emptyDirVolume(mountPath: '/var/run', memory: false),
        hostPathVolume(mountPath: "/etc/docker/certs.d/${env.PRIVATE_REGISTRY}/ca.crt", hostPath: "/etc/docker/certs.d/${env.PRIVATE_REGISTRY}/ca.crt"),
        hostPathVolume(mountPath: '/home/jenkins/.kube/config', hostPath: '/etc/kubernetes/admin.conf'),
        persistentVolumeClaim(claimName: env.HELM_REPOSITORY, mountPath: '/var/helm/', readOnly: false)
    ]) {

    node('es-build') {
        ansiColor('xterm') {
            def image

            stage('git clone') {
                checkout scm
            }

            stage('build image') {
                image = docker.build("${env.PRIVATE_REGISTRY}/library/elasticsearch:${env.BRANCH_NAME}", '--pull .')
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

            stage('push image') {
                withDockerRegistry(url: env.PRIVATE_REGISTRY_URL, credentialsId: 'docker-login') {
                    parallel versioned: {
                        image.push()
                    },
                    failFast: false
                }
            }

            container('helm') {
                stage('package') {
                    sh 'helm init --client-only'
                    sh 'helm lint elasticsearch'
                    sh 'helm package --destination /var/helm/repo elasticsearch'
                    sh """
                    merge=`[[ -e '/var/helm/repo/index.yaml' ]] && echo '--merge /var/helm/repo/index.yaml' || echo ''`
                    helm repo index --url ${env.HELM_PUBLIC_REPO_URL} \$merge /var/helm/repo
                    """
                }
            }

            build job: 'helm-repository/master', parameters: [string(name: 'commiter', value: "${env.JOB_NAME}\ncommit: ${sh(script: 'git log --format=%B -n 1', returnStdout: true).trim()}")]

        }
    }
}

def containerIP(container) {
    return sh(script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${container.id}", returnStdout: true).trim()
}