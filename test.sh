#!/bin/bash

function run_script {
  local version=$1

  echo "Running example in $version"

  valgrind --leak-check=full $version/src/nnet2bin/nnet-train-simple \
    --minibatch-size=256 --srand=0 test.mdl egs.ark /dev/null        \
    > $version.log 2>&1
}

run_script kaldi-upstream
run_script kaldi-fix
