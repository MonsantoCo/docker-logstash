## Logstash Dockerfile

This is a highly configurable [Logstash](https://www.elastic.co/products/logstash) Docker image built using [Docker's automated build](https://registry.hub.docker.com/u/monsantoco/logstash/) process and published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an [Elasticsearch](https://www.elastic.co/products/elasticsearch) instance (document database) and [Kibana](https://www.elastic.co/products/kibana) (as a frontend) to form what is known as an **ELK stack**.


### How to use this image
To start a basic container, specify `--env LS_ES_CONN_STR=[hostname/IP]:[port]` (separate multiple values with comma, ',') for a remote Elasticsearch instance. This will be applied to the default `logstash.conf` file. For example:

```sh
docker run -d --name --publish 5000:5000 --env LS_ES_CONN_STR=elasticsearch.local:9200 monsantoco/logstash
```

> Note that for connecting to an Elasticsearch cluster you should be using a proxy node or load balancer, but you can use `--env LS_ES_CONN_STR=esnode1:9200,esnode2:9200,esnode3:9200` to connect to multiple ES nodes as well.

The included `logstash.conf` file is capable of processing syslog, logstash-forwarder, systemd journal, Logspout Docker logs, and Log4j (just pass-through) content. It is highly recommended that you use your own file for best processing however.

### Additional Configuration
The image exposes a few ports required by the default `logstash.conf` file, namely:

* 5000 (tcp/udp) - Used for syslog
* 5002 (tcp) - Used for [Logstash-Forwarder](https://github.com/elastic/logstash-forwarder)
* 5004 (tcp) - Used for systemd journal
* 5006 (tcp) - Used for [Logspout Docker logs](https://github.com/gliderlabs/logspout)
* 4560 (tcp) - Used for Log4J

These exposed ports should be used in your own file though the purpose can of course be different. You can use your own configuration via [command line](https://www.elastic.co/guide/en/logstash/current/_command_line_flags.html) `-e CONFIG_STRING`, a volume mount (--volume $PWD/conf:/etc/logstash/conf.d) or download URL (--env LS_CFG_URL=http://pastebin.com/4EsKPGNF). Local volume mounted `logstash.conf` example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5006:5006 \
  --publish 4560:4560 \
  --volume /tmp:/etc/logstash/conf.d \
  monsantoco/logstash
```

Remote Logstash configuration file download example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5006:5006 \
  --publish 4560:4560 \
  --env LS_CFG_URL=http://pastebin.com/4EsKPGNF \
  monsantoco/logstash
```

Environment variables are accepted as a means to provide further configuration by reading those starting with `LS_`. Any matching variables will be used as substitution variables within Logstash's configuration file, `logstash.conf' by:

  1. Removing the `LS_` prefix
  2. Substituting the value within the configuration file (`logstash.conf`)

The environment variable substitution also works for your configuration file (host mounted or remote download) as well, for example:

```sh
docker run -d \
  --publish 5000:5000 \
  --env LS_CFG_URL=http://pastebin.com/4EsKPGNF \
  --env LS_ES_CONN_STR=elasticsearch.local:9200
  monsantoco/logstash
```

> Note that the container must be able to access the URL provided, otherwise it will exit with a failure code.

### A note about Logstash Forwarder
This image can use either existing SSL keys and certificates, or create new ones for using Logstash-Forwarder. The latter is always done whenever no files are found in the expected location, `/etc/logstash/ssl`. This is an exposed volume so you can do a host volume mount to use your own files. You can also download your own remote files using the `LSF_CERT_URL` (certificate) and `LSF_KEY_URL` (key) environment variables. The container must be able to access all URLs provided, otherwise it will exit with a failure code.
