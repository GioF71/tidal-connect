#!/bin/bash

docker build . -t my/tidal-connect:latest --progress=plain "$@"