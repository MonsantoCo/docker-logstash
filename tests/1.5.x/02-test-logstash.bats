#!/usr/bin/env bats

@test "Confirm Logstash version ${VERSION}" {
  run docker run -t --rm --name ${DOCKER_IMAGE} ${DOCKER_IMAGE}:${VERSION} --version
  [[ ${lines[2]} =~ "logstash ${VERSION}" ]]
}

@test "Validate default Logstash config file" {
  run docker run -t --rm --name ${DOCKER_IMAGE} ${DOCKER_IMAGE}:${VERSION} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Validate default Logstash shipper config file" {
  run docker run -t --rm --name ${DOCKER_IMAGE} --env LS_CFG_FILE="/etc/logstash/conf.d/logstash-shipper.conf" ${DOCKER_IMAGE}:${VERSION} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Validate default Logstash indexer config file" {
  run docker run -t --rm --name ${DOCKER_IMAGE} --env LS_CFG_FILE="/etc/logstash/conf.d/logstash-indexer.conf" ${DOCKER_IMAGE}:${VERSION} --version
  [[ ${lines[1]} =~ "Configuration OK" ]]
}

@test "Confirm Logstash functionality" {
  # Launch required ES container
  docker run -d --name eslogstash -P monsantoco/elasticsearch:latest >/dev/null
  es_port=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "9200/tcp") 0).HostPort}}' eslogstash)
  es_url="http://${DOCKER_HOST_IP}:${es_port}"
  sleep 15

  # Launch container
  docker run -d --name ${DOCKER_IMAGE} -P --env LS_ES_CONN_STR=$(echo $es_url | cut -d'/' -f3) ${DOCKER_IMAGE}:${VERSION} >/dev/null
  port=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "5000/tcp") 0).HostPort}}' ${DOCKER_IMAGE})
  url="http://${DOCKER_HOST_IP}:${port}"
  run bash -c 'echo '{"@timestamp": "2015-06-09T09:37:45.000Z","@version": "1","count": 2048,"average": 1523.33,"host": "logstash.com"}' | nc -w 1 $host:$port'
  [ $status -eq 0 ]
  docker stop eslogstash logstash
  docker rm -f eslogstash logstash
}
