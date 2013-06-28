#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#start god server
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_god/av.lua pid=god.pid >god.log 2>&1 &
