FROM anapsix/alpine-java

ARG user=elasticsearch
ARG group=elasticsearch
ARG uid=1005
ARG gid=1005

RUN addgroup -g ${gid} ${group} \
    && adduser -u ${uid} -G ${group} -s /bin/bash -D ${user}

ENV VERSION 2.3.3
RUN apk add --no-cache --virtual .fetch-deps curl && \
    curl -Ls https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 > /usr/local/bin/dumb-init && \
    chmod +x /usr/local/bin/dumb-init && \
    mkdir -p /opt && \
    curl -Ls https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/${VERSION}/elasticsearch-${VERSION}.tar.gz | tar xz && \
    mv /elasticsearch-$VERSION /opt/elasticsearch && \
    rm -rf $(find /opt/elasticsearch | egrep "(\.(exe|bat)$|sigar/.*(dll|winnt|x86-linux|solaris|ia64|freebsd|macosx))") && \
    apk del .fetch-deps && \
    rm -rf /var/cache/apk && \
    chown -R ${user} /opt/elasticsearch

COPY run.sh /opt/elasticsearch/bin/run.sh

EXPOSE 9200
EXPOSE 9300
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
ENV PATH=$PATH:/opt/elasticsearch/bin
ENV ES_HEAP_SIZE=256m
CMD ["run.sh", "elasticsearch", "-Dnetwork.host=0.0.0.0", "-Dbootstrap.mlockall=true"]
