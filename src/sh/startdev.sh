#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#start god server
./lolita corext=../src/corext/co.lua avatar=../src/avatar/srv_god/av.lua pid=god.pid >god.log 2>&1 &
sleep 3s

#start login server
./lolita corext=../src/corext/co.lua avatar=../src/avatar/srv_login/av.lua pid=login.pid >login.log 2>&1 &

#start area server
#area server will connect to god server
./lolita corext=../src/corext/co.lua avatar=../src/avatar/srv_area/av.lua pid=area.pid >area.log 2>&1 &

#start mind server
#mind server will connect to god server
./lolita corext=../src/corext/co.lua avatar=../src/avatar/srv_mind/av.lua pid=mind.pid >mind.log 2>&1 &

echo "all server is startup"
