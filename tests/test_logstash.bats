#!/usr/bin/env bats

@test "Confirm JDK version 1.8.0_45-b14" {
  run docker run --rm --name ${IMAGE} ${IMAGE}:${TAG} /usr/local/java/jdk/bin/java -version
  [[ ${lines[1]} =~ "1.8.0_45-b14" ]]
}

@test "Confirm Logstash version ${TAG}" {
  run docker run -t --rm --name ${IMAGE} ${IMAGE}:${TAG} --version
  [[ ${lines[2]} =~ "logstash ${TAG}" ]]
}

@test "Validate default Logstash config file" {
  run docker run -t --rm --name ${IMAGE} ${IMAGE}:${TAG} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Validate default Logstash shipper config file" {
  run docker run -t --rm --name ${IMAGE} --env LS_CFG_FILE="/etc/logstash/conf.d/logstash-shipper.conf" ${IMAGE}:${TAG} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Validate default Logstash indexer config file" {
  run docker run -t --rm --name ${IMAGE} --env LS_CFG_FILE="/etc/logstash/conf.d/logstash-indexer.conf" ${IMAGE}:${TAG} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Confirm Logstash functionality" {
  host=$(echo $DOCKER_HOST|cut -d":" -f2|sed -e 's/\/\///')

  # Launch required ES container
  docker run -d --name eslogstash -P monsantoco/elasticsearch:latest >/dev/null
  es_port=$(docker port eslogstash | grep 9200 | cut -d":" -f2)
  es_url="http://${host}:${es_port}"

  sleep 15

  # Launch container
  docker run -d --name ${IMAGE} -P --env LS_ES_CONN_STR=$(echo $es_url | cut -d'/' -f3) ${IMAGE}:${TAG} >/dev/null
  port=$(docker port ${IMAGE} | grep 5000 | cut -d":" -f2)
  url="http://${host}:${port}"
  run bash -c 'echo '{"@timestamp": "2015-06-09T09:37:45.000Z","@version": "1","count": 2048,"average": 1523.33,"host": "logstash.com"}' | nc -w 1 $host:$port'
  [ $status -eq 0 ]
  docker kill eslogstash logstash
  docker rm eslogstash logstash
}

