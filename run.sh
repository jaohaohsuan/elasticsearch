#!/bin/bash
set -e
ulimit -l unlimited
exec su -m elasticsearch -c "$*"
