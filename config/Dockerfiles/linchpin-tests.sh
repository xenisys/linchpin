#!/bin/bash -x

base_dir="$( pwd )"

set -o pipefail

mkdir -p ${base_dir}/${distro}_logs

result=0
for provider in $PROVIDERS; do
    export CREDS_PATH="$base_dir/keys/${provider}"
    # If CREDS_PATH provides a tarball extract it and
    # run it's install script
    if [ -e "$CREDS_PATH/${provider}.tgz" ]; then
        tmpdir=$(mktemp -d)
        tar xvf $CREDS_PATH/${provider}.tgz -C $tmpdir
        $tmpdir/install.sh
    fi
    TESTS=$(cat config/Dockerfiles/tests.d/${provider}.tests)
    > ${distro}_logs/${provider}.log
    for test in ${TESTS}; do
        filename=$(basename -- ${test})
        tname="${filename%.*}"
        testname="${distro}/${provider}/${tname}"
        ./config/Dockerfiles/tests.d/${test} ${distro} ${provider} 2>&1 | tee -a ${distro}_logs/${provider}.log
        if [ $? -eq 0 ]; then
            test_summary="$(tput setaf 2)SUCCESS$(tput sgr0)\t${testname}"
        else
            test_summary="$(tput setaf 1)FAILURE$(tput sgr0)\t${testname}\tlog: logs/${distro}_logs/_${provider}.log"
            result=1
        fi
        summary="${summary}\n${test_summary}"
    done
done

printf "\n==== TEST summary ====${summary}\n"
exit $result
