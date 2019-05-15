#!/usr/bin/env bash

if [ "$1" == "train" ]; then
    if [ -f /opt/ml/input/config/resourceconfig.json ]; then
        # CURRENT_HOST="algo-1"
        CURRENT_HOST=$(jq .current_host  /opt/ml/input/config/resourceconfig.json)
    else
        CURRENT_HOST="0"
    fi

    echo "CURRENT_HOST=${CURRENT_HOST}"

    sed -ie "s/PLACEHOLDER_HOSTNAME/${CURRENT_HOST}/g" /changehostname.c

    gcc -o /changehostname.o -c -fPIC -Wall /changehostname.c
    gcc -o /libchangehostname.so -shared -export-dynamic /changehostname.o -ldl

    LD_PRELOAD=/libchangehostname.so train
else
    serve
fi
