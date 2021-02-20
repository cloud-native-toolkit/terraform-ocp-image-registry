#!/usr/bin/env bash

OUTPUT_FILE="$1"

if oc whoami --show-console 1> /dev/null 2> /dev/null; then
  ROUTE_URL=$(oc whoami --show-console)
elif oc get route -n openshift-console console 1> /dev/null 2> /dev/null; then
  ROUTE=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}')
  ROUTE_URL="https://${ROUTE}"
fi

if [[ -z "${ROUTE_URL}" ]]; then
  echo "The console host could not be found"
  exit 1
fi

echo -n "${ROUTE_URL}" > "${OUTPUT_FILE}"
