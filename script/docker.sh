#!/bin/bash

JOB_EVAL_DIR=$(pwd)/../hex_faktor-workdir/script-docker-eval
JOB_CODE_DIR=$(pwd)/

mkdir -p $JOB_EVAL_DIR



case "$1" in
  s|setup)
    docker run -ti -v $(pwd)/dockertools:/tools faktor-elixir /tools/mix/hex_faktor/setup.sh
    ;;
  *)
    docker run -ti -v $(pwd)/dockertools:/tools -v $JOB_CODE_DIR:/job/code -v $JOB_EVAL_DIR:/job/eval faktor-elixir bash
    ;;
esac
