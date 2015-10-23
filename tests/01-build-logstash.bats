#! /usr/bin/env bats

@test "Check Logstash build" {
  run docker build -t ${DOCKER_IMAGE}:${VERSION} ${VERSION}
  [ $status = 0 ]
}
