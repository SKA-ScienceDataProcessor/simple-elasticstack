FROM kibana:5.4.0

RUN /usr/share/kibana/bin/kibana-plugin  install https://github.com/sivasamyk/logtrail/releases/download/0.1.13/logtrail-5.4.0-0.1.13.zip

COPY logtrail.json /usr/share/kibana/plugins/logtrail/logtrail.json
