# Bringing up the ELK services

To prove and solve Logit event loss, we need ES and LS services to write to.
We'll start with LS, and if we can't observe event loss, we'll put a TCP proxy
in front of it with a 50s client timeout (which is what Logit does).

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