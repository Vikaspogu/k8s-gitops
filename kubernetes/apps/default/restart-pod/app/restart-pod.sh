#!/usr/bin/env bash

set -o nounset
set -o errexit

kubectl delete -n home $(kubectl get pod -n home -o name | grep "garage-opener")
