#!/bin/bash
# `oc --as=username ...` requires user to be properly authenticated
oc login --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST --token="$(cat /run/secrets/kubernetes.io/serviceaccount/token)" || exit 1
echo 'Starting goss tests'
date
OK=0
goss -g /test/goss.yaml --vars /test/goss_vars.yaml validate --format tap || OK=1
date
exit ${OK}
