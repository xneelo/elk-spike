# Testing Logit event loss

This repo is intended to prove an issue with event loss with the Logit TCP input,
arising from poor interaction between the `logstash-logger` gem and the `haproxy`
that front the Logit input.

It includes the following `docker-compose` files, all of which use the same bridge
network, named `elknet`.

* `docker-compose.elk.yml`     - ElasticSearch, LogStash and Kibana
* `docker-compose.haproxy.yml` - TCP proxy for LogStash TCP input
* `docker-compose.rspec.yml`   - Test that demonstrates the issue.

Multiple `docker-compose` files are used to cope with the fact that the `elk`
container takes forever to start up and requires some first-time manual setup.

## Bringing up the ELK services

The `docker-compose.elk.yml` file brings up an ELK stack.

* Requires `sudo sysctl -w vm.max_map_count=262144` at minimum.
* Bring up the ELK stack: `docker-compose -f docker-compose.elk.yml up`.  This takes a long time.
  You'll know it's done when you can visit Kibana without a timeout or
  error message: http://localhost:5601
* To verify that your stack came up, exec into the `elk` container and create a dummy log message:
  ```
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

## Bringing up the haproxy

The `docker-compose.elk.yml` file brings up an haproxy to simulate Logit's Logstash TCP input proxy.

* Bring up the haproxy: `docker-compose -f docker-compose.haproxy.yml up`.

## Manual testing

You can now start logging to `localhost:16500` to observe the behaviour of the logger when Logstash does not drop connections,
or to `localhost:16700` to observe the behaviour of the logger when an aggressive proxy is in front of Logstash (as is the case
with Logit). Logger writes that occur more than 30 seconds since the last successful write will be lost to an `Errno::EPIPE`
exception.

## Spec-based testing

The `docker-compose.rspec.yml` file runs a simple rspec test against Logstash, haproxy with timeouts or haproxy with keepalives.

* Test Logstash (no timeouts): `docker-compose -f docker-compose.rspec.yml run test` *[PASS]*
* Test haproxy with timeouts: `docker-compose -f docker-compose.rspec.yml run test-timeouts` *[FAIL]*
* Test haproxy with keepalives: `docker-compose -f docker-compose.rspec.yml run test-keepalives` *[PASS]*

