#!/bin/bash

docker-compose up -d --force-recreate
docker-compose logs -f