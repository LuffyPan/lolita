#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#顺序问题以后再来解决
#stop servers
kill -s INT $(cat mind.pid)
kill -s INT $(cat login.pid)
kill -s INT $(cat area.pid)
kill -s INT $(cat god.pid)
