#!/usr/bin/env bash

set -o nounset
set -o errexit

while :
do
    exec "python3" "/usr/src/app/data-read.py"
    sleep 5m
done
