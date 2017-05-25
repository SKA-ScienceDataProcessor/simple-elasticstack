# Yet another ELK

Yet another ELK is a set of notes for me to remember how to standup up a Docker based demonstration solution for Elasticsearch, Logstash, Kibana and MetricBeat as an instant platform for time-series (mostly) based Analytics.

## Background

This implementation of ElasticStack is designed as a minimal set of tools to log and monitor hosts running containers giving both container and host metrics as well as channelling any logging that uses journald or syslog.

## Environment

Built and tested on Ubuntu 16.04. YMMV. It will at least required systemd and journald.

## Installing dependencies

* Docker 17.04ce+ - https://docs.docker.com/engine/installation/linux/ubuntu/
* docker-compose  1.13.0+ - https://docs.docker.com/compose/install/
* Ansible 2.2.1+ - http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-apt-ubuntu
* for entropy starved problems with logstash install haveged - `sudo apt-get install haveged`


## Preparing the host

### Configure Docker

Switch the docker engine to using journald as the logging driver, set some tag options.  Using journald has the advantage of being able to forward the messages from docker but also still retain the use of the command line tools such as `docker logs -f <container name>`.

In /lib/systemd/system/docker.service:
```
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --log-driver=journald --log-opt tag="img={{.ImageName}} name={{.Name}} cid={{.ID}}" --log-opt labels="com.docker.swarm.service.name,com.docker.swarm.task.name" --label nodetype=manager --experimental=true --dns <some internal DNS server IP> --dns 8.8.8.8 --dns 8.8.4.4
```
Restart the docer daemon with:
```
systemctl daemon-reload
systemctl restart docker.service
```

### Setup journald and rsyslogd

Forward journald logs to syslog, and then forward the combined logging to a logstash receiver.

In /etc/systemd/journald.conf:
```
[Journal]
...
ForwardToSyslog=yes
...
```

In /etc/rsyslog.conf at the top of the file:
```
$MaxMessageSize 64k
```
This sets the maximum message size which shoul stop logging JSON messages from being truncated.


In /etc/rsyslog.d/50-default.conf at the top of the file:
```
*.*                         @localhost:9514;json-template
```
Where @localhost is @<IP of logstash forwarder>. Switch to using @@ to forward over TCP - this maybe necessary if message lengths exceed standard UDP packet size or there are message delivery guarantee concerns.

Create the JSON message output template in /etc/rsyslog.d/01-json-template.conf:
```
template(name="json-template"
  type="list") {
    constant(value="{")
      constant(value="\"@timestamp\":\"")     property(name="timereported" dateFormat="rfc3339")
      constant(value="\",\"@version\":\"1")
      constant(value="\",\"message\":\"")     property(name="msg" format="json")
      constant(value="\",\"sysloghost\":\"")  property(name="hostname")
      constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
      constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
      constant(value="\",\"programname\":\"") property(name="programname")
      constant(value="\",\"procid\":\"")      property(name="procid")
    constant(value="\"}\n")
}
```

Now reload and restart the associated services:
```
systemctl daemon-reload
systemctl restart systemd-journald.service

/etc/init.d/rsyslog restart
```
The above has been some what automated using an ansible playbook which can be run locally to the target host using:
```
ansible-playbook configure-logging.yml
```
This can potentially be modified to run across remote inventory instead of loading and running on each machine.  Create a file with the remote host name in it eg: /tmp/hosts:
```
my_remote_host
```

Then run it with something like:
```
ansible-playbook -i /tmp/hosts configure-logging.yml --extra-vars "variable_host=my_remote_host"
```
You must make sure that ssh works to the remote host, and the remote user can sudo.


## build using docker-compose

docker-compose will pull down and/or build the necessary containers, and then launch the entire stack.  This can be done using either:

```
./compose-up.sh # looks for the IP of interfaces wlan0|eth0|ens3
```

or:

```
# set the IP address variable for the current server eg:
export LOGSTASH_IP="1.2.3.4"
docker-compose up
```
From the project directory.  Add `-d` to background this.


## Inital setup for Kibana

Kibana is listening on http://<host ip>:5601/.  Select the ["Management"](http://localhost:5601/app/kibana#/management/kibana/index) tab in the left hand list and register the two index patterns one at a time -  "rsyslog-*" and "metrics-*".  Ensure that "@timstamp" is selected as the "Time-field name" for each and set rsyslog as the default one.

* Kibana visualisation tutorial https://www.elastic.co/guide/en/kibana/current/tutorial-visualizing.html
* TimeLion https://www.elastic.co/guide/en/kibana/current/timelion.html
* And don't forget LogTrail - https://github.com/sivasamyk/logtrail


## Tearing it all down

To clean up, first stop and remove the stack:
```
docker-compose stop # if -d option used else ctl-C
docker-compose rm
```
Then remove the data directory for ElasticSearch with `sudo rm -rf /srv/elk` .


