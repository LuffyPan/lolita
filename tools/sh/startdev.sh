#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

mkdir pids
mkdir logs
#lolitax is in the same dir with lolita

echo "starting vgod....."
./lolita x=../../lolitax/src/x.lua,../../lolitavgod/src/x.lua xlvs=[x=4] pid=pids/vgod.pid >logs/vgod.log 2>&1 &
sleep 3

echo "starting vauth....."
./lolita x=../../lolitax/src/x.lua,../../lolitavauth/src/x.lua xlvs=[x=4] pid=pids/vauth.pid >logs/vauth.log 2>&1 &
sleep 3

echo "starting vsoul....."
./lolita x=../../lolitax/src/x.lua,../../lolitavsoul/src/x.lua xlvs=[x=4] pid=pids/vsoul.pid >logs/vsoul.log 2>&1 &
sleep 3

echo "starting varea....."
./lolita x=../../lolitax/src/x.lua,../../lolitavarea/src/x.lua xlvs=[x=4] pid=pids/varea.pid >logs/varea.log 2>&1 &
sleep 3

echo "starting vgate....."
./lolita x=../../lolitax/src/x.lua,../../lolitavgate/src/x.lua xlvs=[x=4] pid=pids/vgate.pid >logs/vgate.log 2>&1 &
sleep 3

echo "all is startup"
