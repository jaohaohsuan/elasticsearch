#!/bin/bash
set -e
ulimit -l unlimited
export ES_JAVA_OPTS="-Des.cgroups.hierarchy.override=/ $ES_JAVA_OPTS"
if [[ -d ${ES_PATH_DATA} ]]; then
	chown elasticsearch.elasticsearch ${ES_PATH_DATA}
fi
exec su -m elasticsearch -c "$*"
