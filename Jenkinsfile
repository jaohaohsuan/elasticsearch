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

          stage('git clone') {
              checkout scm
          }

          def image

          stage('build image') {
              image = docker.build("${env.PRIVATE_REGISTRY}/library/elasticsearch:${env.BRANCH_NAME}", '--pull .')
          }

          stage('test image') {
              image.withRun('--privileged -e ES_HEAP_SIZE=64m --network=host', 'run.sh elasticsearch -Dbootstrap.mlockall=true') { c ->
                def server = "http://127.0.0.1:9200"
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

          
    }
  }
}