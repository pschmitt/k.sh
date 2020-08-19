#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") [NAMESPACE]"
}

EXTRA_ARGS=()

case "$1" in
  help|--help|-h)
    usage
    exit 0
    ;;
  *)
    EXTRA_ARGS+=(--namespace "$1")
    ;;
esac

kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found "${EXTRA_ARGS[@]}"
