#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#start login server
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_login/av.lua pid=login.pid >login.log 2>&1 &

#start god server
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_god/av.lua pid=god.pid >god.log 2>&1 &
sleep 3s

#start gov server
#gov server will connect to god
#gov server will accept from area
#gov server will accept from sa
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_gov/av.lua pid=gov.pid >gov.log 2>&1 &
sleep 3s

#start area server
#area server will connect to gov
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_area/av.lua pid=area.pid >area.log 2>&1 &

#start sa server
#sa server will connect to login god gov server
./lolicore corext=../src/corext/co.lua avatar=../src/avatar/srv_sa/av.lua pid=sa.pid >sa.log 2>&1 &

echo "all server is startup"
