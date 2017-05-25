#!/bin/sh

echo "removing containers..."
docker rm -f elk_metrics elk_kibana elk_logstash elk_elasticsearch

# sudo rm -rf /srv/elk/*

echo "launching containers..."
export DEV=`ip link | grep -E 'wlan|etho|ens3' | awk '{ print $2 }' | sed 's/://'`
export LOGSTASH_IP=`ifconfig ${DEV} | grep "inet " | awk '{ print $2 }'`

 # launch Elasticsearch
echo "ElasticSearch"
sudo mkdir -p /srv/elk/elasticsearch
docker run --name=elk_elasticsearch --restart always \
  -v /srv/elk/elasticsearch:/usr/share/elasticsearch/data \
  -p 9200:9200  -p 9300:9300 \
  -e ES_JAVA_OPTS="-Xms512m -Xmx512m" \
  -d elasticsearch:5.4.0-alpine \
      -Ebootstrap.memory_lock="true" \
      -Ecluster.name="elk" \
      -Ediscovery.zen.minimum_master_nodes="1" \
      -Ehttp.host="0.0.0.0" \
      -Enetwork.host="0.0.0.0" \
      -Etransport.host=127.0.0.1

# launch Kibana
echo "Kibana"
docker run --name=elk_kibana --restart always --link elk_elasticsearch:elasticsearch \
 -p 5601:5601 -d kibana-with-logtrail:5.4.0 kibana -e http://elasticsearch:9200

# launch central Logstash
echo "Logstash"
sudo mkdir -p /srv/elk/logstash
docker run -d --restart always \
    -v $(pwd)/pipeline:/usr/share/logstash/pipeline:ro \
    -v /var/log/journal:/var/log/journal:ro \
    -v /srv/elk/logstash:/var/lib/logstash:z \
    -v /sys:/sys:ro \
    -p 5044:5044 \
    -p 9514:9514/tcp \
    -p 9514:9514/udp \
    --name elk_logstash \
    --link elk_elasticsearch:elasticsearch \
    -e LOGSPOUT=ignore \
    logstash-with-config:5.4.0 \
    logstash -f /usr/share/logstash/pipeline/logstash.conf

# launch an instance of the metricbeat plumbed into logstash
echo "MetricsBeat"
docker run -d --restart always \
  --volume=/proc:/hostfs/proc:ro \
  --volume=/sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro \
  --volume=/:/hostfs:ro \
  --volume=$(pwd)/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml \
  --net=host \
  --name elk_metrics \
    --add-host logstash:${LOGSTASH_IP} \
  docker.elastic.co/beats/metricbeat:5.4.0 metricbeat -e -system.hostfs=/hostfs

echo "done."