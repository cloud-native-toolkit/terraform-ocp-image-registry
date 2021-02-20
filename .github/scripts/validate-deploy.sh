#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

export KUBECONFIG="${PWD}/.kube/config"

CLUSTER_TYPE="$1"
NAMESPACE="$2"
NAME="$3"
CONSOLE_LINK_NAME="$4"

CONFIGMAP_NAME="registry-config"
SECRET_NAME="registy-access"

# Test that configmap has been created
if ! kubectl get configmap -n "${NAMESPACE}" "${CONFIGMAP_NAME}" 1> /dev/null 2> /dev/null; then
  echo "The configmap doesn't exist: ${CONFIGMAP_NAME}"
  exit 1
fi

# Test that configmap has ACTUAL_REGISTRY_URL that points to {CONSOLE_HOST}/k8s/all-namespaces/imagestreams
CONSOLE_HOST=$(kubectl get -n openshift-console route/console -o jsonpath='{.spec.host}')
EXPECTED_REGISTRY_URL="https://${CONSOLE_HOST}/k8s/all-namespaces/imagestreams"

ACTUAL_REGISTRY_URL=$(kubectl get configmap -n "${NAMESPACE}" "${CONFIGMAP_NAME}" -o jsonpath '{.data.ACTUAL_REGISTRY_URL}')
if [[ "${ACTUAL_REGISTRY_URL}" != "${EXPECTED_REGISTRY_URL}" ]]; then
  echo "The configmap REGISTRY_URL does not match the expected value. Expected: ${EXPECTED_REGISTRY_URL}, Actual: ${ACTUAL_REGISTRY_URL}"
  exit 1
fi

# Test that secret has been created
if ! kubectl get secret -n "${NAMESPACE}" "${SECRET_NAME}" 1> /dev/null 2> /dev/null; then
  echo "The secret doesn't exist: ${SECRET_NAME}"
  exit 1
fi

# Test that secret has ACTUAL_REGISTRY_URL of image-registry.openshift-image-registry.svc:5000
EXPECTED_INTERNAL_REGISTRY_URL="image-registry.openshift-image-registry.svc:5000"
ACTUAL_INTERNAL_REGISTRY_URL=$(kubectl get secret -n "${NAMESPACE}" "${SECRET_NAME}" -o jsonpath '{.data.REGISTRY_URL}' | base64 -D)

if [[ "${ACTUAL_INTERNAL_REGISTRY_URL}" != "${EXPECTED_INTERNAL_REGISTRY_URL}" ]]; then
  echo "The secret REGISTRY_URL does not match the expected value. Expected: ${EXPECTED_INTERNAL_REGISTRY_URL}, Actual: ${ACTUAL_INTERNAL_REGISTRY_URL}"
  exit 1
fi

# Test that console link was created
if [[ "${CLUSTER_TYPE}" == "ocp4" ]] && [[ -n "${CONSOLE_LINK_NAME}" ]]; then
  if ! kubectl get consolelink "${CONSOLE_LINK_NAME}" 1> /dev/null 2> /dev/null; then
    echo "Console link not found: ${CONSOLE_LINK_NAME}"
    exit 1
  fi
else
  echo "Cluster type is not ocp4 or console link name not set. Skipping console link check. ${CLUSTER_TYPE}, ${CONSOLE_LINK_NAME}"
fi
