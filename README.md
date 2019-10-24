# Bringing up the ELK services

This docker compose graph provides a Logstash TCP input with optional TCP proxy that aggressively times clients out,
to simulate Logit's behaviour.

* Requires `sudo sysctl -w vm.max_map_count=262144` at minimum.
* Bring up the stack: `docker-compose up`.  This takes a long time.
  You'll know it's done when you can visit Kibana without a timeout or
  error message: http://localhost:5601
* To verify that your stack came up, exec into the `elk` container and create a dummy log message: ```
  $ docker-compose exec elk /bin/bash
  root@f5b68a55f6d8:/# /opt/logstash/bin/logstash \
    --path.data /tmp/logstash/data \
    -e 'input { stdin { } } output { elasticsearch { hosts => ["localhost"] } }'
  ... a long time passes ...
  ... Successfully started Logstash API endpoint {:port=>9601}
  this is a dummy entry
  ^C
  $ curl -s http://localhost:9200/_search?pretty | grep dummy
            "message" : "this is a dummy entry",
  ```
* Configure Kibana to search the index:
  * Visit http://localhost:5601/app/kibana#/management/kibana/index_pattern?_g=()
  * Enter `logstash-*` into `Index pattern`
  * Click `Next step`
  * Select `@timestamp` under `Time Filter field name`
  * Click `Create index pattern`
* Now browse Kibana Discover to verify that you can see your dummy entry: http://localhost:5601/app/kibana#/discover

You can now start logging to `localhost:16500` to observe the behaviour of the logger when Logstash does not drop connections,
or to `localhost:16600` to observe the behaviour of the logger when an aggressive proxy is in front of Logstash (as is the case
with Logit). Logger writes that occur more than 30 seconds since the last successful write will be lost to an `Errno::EPIPE`
exception.
