#!/bin/bash

####
# reusable functions
####



setup_stan() {
  pushd ~/dev/stan
  git clean -d -x -f; rm make/local;

  ### checkout!
  git checkout $1

  echo "CC=clang++" > make/local
  echo "O=3" >> make/local
  echo "MAKEFLAGS=-j4" >> make/local
  echo "O_STANC=3" >> make/local
  popd

  ## copy test files over
  cp src/tests ~/dev/stan/make/tests
  mkdir -p ~/dev/stan/src/test/performance
  cp src/logistic_test.cpp ~/dev/stan/src/test/performance/
  cp src/utility.hpp ~/dev/stan/src/test/performance/
  mkdir -p ~/dev/stan/src/test/test-models/performance
  cp src/logistic.data.R ~/dev/stan/src/test/test-models/performance/
  cp src/logistic.stan ~/dev/stan/src/test/test-models/performance/
#  cp src/runTests.py ~/dev/stan
  mkdir -p ~/dev/stan/test/performance
  cp performance.csv ~/dev/stan/test/performance/performance.csv
}

run_test_with_lib() {
  pushd ~/dev/stan

  make bin/libstan.a
  make src/test/test-models/performance/logistic.hpp
  make test/performance/logistic
  ./test/performance/logistic

  popd
  
  cp ~/dev/stan/test/performance/performance.csv .
}

run_test_without_lib() {
  pushd ~/dev/stan

  make src/test/test-models/performance/logistic.hpp
  make test/performance/logistic
  ./test/performance/logistic

  popd
  
  cp ~/dev/stan/test/performance/performance.csv .
}

clean_stan() {
  pushd ~/dev/stan
  git clean -d -x -f
  git checkout -- .
  popd
}


test_with_lib() {
  setup_stan $1
  run_test_with_lib
  clean_stan  
}

test_without_lib() {
  setup_stan $1
  run_test_without_lib
  clean_stan  
}


test_with_lib tags/v2.5.0
test_with_lib 1e616a3a7d08500b91c16135080696ca59cd4938
test_with_lib 182d1b2af62ea40cf62f78077885e34d826593af
test_with_lib 77a0cc4db76359c3b39427b298727d648c0f8c5e
test_with_lib aa84dbb55863668ba677cd81ad9ff00988c21478
test_with_lib 73309790b298daa274752106825fcd7cdefb802a
test_with_lib b4a361351b4a9e4011a6f73c6d3902c47ba0cf70
test_with_lib ea39c6b31cdc58c0e1eae2f121789e11329f73f8
test_with_lib b9779048f83f6501f01e4d5da4a511700f595e84
test_with_lib 429d95186c49b1499f59b33e8ea8b2212cc339eb
test_with_lib 616f9a5ddd219d03abc1dd204034e572396b4ec4
test_with_lib a0ae5d65d0bb1aebe66a345edef3f2671db8ae54
test_with_lib 6bb03690e89e1270482b48290d6ee4f2ec275971
test_with_lib e6193fd8aa135acf4f681fe9722c162ddd05cec0
test_with_lib c0306f2a6ad44801b4ccf4e50ee48ec13676b78f
test_with_lib edda77231bbb2ecb49f0c2de5cdfa198c2822fc3
test_with_lib 632dafec6d1b739ecdfbcfade539c5062e3d2e5b
test_with_lib c597e827cedf34a56ad5ffd83ce0f1b635213f8e
test_with_lib b6408a7aa4687058ce158ea0c3904fb7b3e92fa7
test_with_lib 0198629a47820d283dd54a0ea444cba506375c70
test_with_lib d01a3e1b13b062ca7d8d3e92f419615cf9229ee8
test_without_lib 77e0312d6292e1a215377ea05c59da9510c82cb7
test_without_lib 89c474a1d6b9555cc6ea9259ac0f20268764288b
test_without_lib 9c84bb48d51d231430a94fb1a1e375c614b369db
test_without_lib 6e1a91c70f5e50c429953d4b5abf0c49a0d8fe5e
test_without_lib 97d7a747988700d5dd3a76561920b1aef911f127
test_without_lib 9e90fff5e01b9f9a0655a5d0ed2dca9725e04752
test_without_lib 485bc2f43eeb26e130b80236b07aa2fc9528d8e2
test_without_lib 91b90c794711b7364623e99c4623015762e4c580
test_without_lib dc61f6fb4508b3b6e10a7bc6e5d8966b248a3330
test_without_lib 9e54e4f1aa4d9e642b47cba6038aa56fe5212416
test_without_lib 38c259f1e5febe48e196e75a351fca0e526d026b
test_without_lib 35e8aec484ea4a338dd53d04585f7c35abea3e21
test_without_lib 838e2ebaba1ab8bcc1147a1881bb6be4368f9909
test_without_lib 6dd1ec872173ab64f9f5270231ebaca7e601b90a
test_without_lib 1bd0434b3966351770b87422ef23ff746524a8bc
test_without_lib bc419f1f5ff6e30ccb4e7200d129dffa19d5341a
test_without_lib 069d9f9fdda39612f7d447af0bb5a1d81cd86265
test_without_lib 0b7a10fde5b639f431507d38beb79f952a297a93

