#!/bin/bash
set -e
ulimit -l unlimited
export ES_JAVA_OPTS="-Des.cgroups.hierarchy.override=/ $ES_JAVA_OPTS"
exec su -m elasticsearch -c "$*"
