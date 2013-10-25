#!/bin/sh

basedir=$(cd "$(dirname "$0")"; pwd)
echo "path to script is: [$0]"
echo "path to script's dir is: [${basedir}]"
cd ${basedir}
echo "change working dir to $(pwd)"

#stop all

echo "stoping vgate....."
kill -s INT $(cat pids/vgate.pid)
sleep 3

echo "stoping vauth....."
kill -s INT $(cat pids/vauth.pid)
sleep 3

echo "stoping varea....."
kill -s INT $(cat pids/varea.pid)
sleep 3

echo "stoping vsoul....."
kill -s INT $(cat pids/vsoul.pid)
sleep 3

echo "stoping vgod....."
kill -s INT $(cat pids/vgod.pid)
sleep 3

echo "all is stoped"
