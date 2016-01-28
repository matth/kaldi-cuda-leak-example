#!/bin/bash

function run_script {
  local version=$1

  echo "Running example in $version"

  valgrind --leak-check=full $version/src/nnet2bin/nnet-train-simple \
    --minibatch-size=512 --srand=33 test.mdl ark:egs.ark             \
    /dev/null  > $version.log 2>&1
}

run_script kaldi-upstream
run_script kaldi-fix
