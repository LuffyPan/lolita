#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#lolitax is in the same dir with lolita

./lolita x=../../lolitax/src/x.lua xlvs=[x=4] pid=x.pid >x.log 2>&1 &
echo "all is startup"
