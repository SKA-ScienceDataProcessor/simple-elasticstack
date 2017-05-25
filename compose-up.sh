#!/bin/sh

# sudo rm -rf /srv/elk/* # only if you want to wipe the ES database

echo "launching containers..."
export DEV=`ip link | grep -E 'wlan|etho|ens3' | awk '{ print $2 }' | sed 's/://'`
export LOGSTASH_IP=`ifconfig ${DEV} | grep "inet " | awk '{ print $2 }'`
sudo mkdir -p /srv/elk/elasticsearch
sudo mkdir -p /srv/elk/logstash

docker-compose up
