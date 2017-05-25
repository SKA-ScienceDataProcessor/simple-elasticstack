FROM docker.elastic.co/logstash/logstash:5.4.0

RUN JARS_SKIP=true /usr/share/logstash/bin/logstash-plugin install x-pack
RUN JARS_SKIP=true /usr/share/logstash/bin/logstash-plugin install logstash-input-journald

# These break us!!!
#RUN JARS_SKIP=true /usr/share/logstash/bin/logstash-plugin install logstash-input-kafka
#RUN JARS_SKIP=true /usr/share/logstash/bin/logstash-plugin install logstash-output-kafka

COPY types.db /usr/share/logstash/vendor/bundle/jruby/1.9/gems/logstash-codec-collectd-3.0.3/vendor/types.db

COPY config/ /usr/share/logstash/config/
COPY pipeline/ /usr/share/logstash/pipeline/

COPY boot.sh /

CMD ["-f", "/usr/share/logstash/pipeline/logstash.conf"]
