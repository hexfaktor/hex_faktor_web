#!/bin/bash

# remove all docker containers for HexFaktor
docker ps -a | grep 'hf-job-' | awk '{print $1}' | xargs --no-run-if-empty docker rm


# remove all workdirs for HexFaktor
rm -fr tmp/0000
rm -fr ../hex_faktor-workdir/0000

# reset database
MIX_ENV=dev mix ecto.reset
