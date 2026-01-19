#!/bin/bash

docker run --rm -it -p 80:80 \
  -e BASIC_USER=houdadh -e BASIC_PASS=Helloearth1234 \
  -e MYSQL_DATABASE=wordpress -e MYSQL_USER=houdadh -e MYSQL_PASSWORD=Helloearth1234 \
  -e AUTO_INDEX=off \
  examen
