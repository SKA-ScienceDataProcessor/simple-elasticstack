#!/bin/sh

logstash -f /usr/share/logstash/pipeline/logstash.conf >/dev/null 2>&1
#logstash -f /usr/share/logstash/pipeline/logstash.conf
