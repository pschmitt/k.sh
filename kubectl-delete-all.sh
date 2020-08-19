#!/usr/bin/env bash

DELETION_TIMEOUT="${DELETION_TIMEOUT:-3}"

usage() {
  echo "Usage: $(basename "$0") [-d] [-t] -n NAMESPACE"
}

kubectl_delete_all() {
  timeout "$DELETION_TIMEOUT" kubectl -n "$1" delete "$2" --all
}

kubectl_burn() {
  local item
  local ns="$1"
  local res="$2"

  for item in $(kubectl -n "$ns" get "$res" -o name)
  do
    kubectl -n "$ns" patch --type=merge "$item" \
      -p '{"metadata":{"finalizers": []}}'
    if ! kubectl_delete_all "$ns" "$res"
    then
      echo "Deletion of $item timed out"
    fi
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  NAMESPACE=
  DELETE_NAMESPACE=
  PASSES=1

  while [[ -n "$*" ]]
  do
    case "$1" in
      help|--help|-h)
        usage
        exit 0
        ;;
      -n|--namespace)
        NAMESPACE="$2"
        shift 2
        ;;
      -d|--delete)
        DELETE_NAMESPACE=1
        shift 1
        ;;
      -t|--thorough)
         (( PASSES = PASSES + 1 ))
         shift 1
        ;;
      *)
        echo "Unknown arg: $1"
        usage
        exit 2
        ;;
    esac
  done

  if [[ -z "$NAMESPACE" ]]
  then
    usage
    exit 2
  fi

  for pass in $(seq "$PASSES")
  do
    if [[ "$PASSES" -gt 1 ]]
    then
      echo "Pass number $pass" >&2
    fi

    for res in $(kubectl api-resources --verbs=list --namespaced -o name)
    do
      # echo "Delete all of $res" >&2
      kubectl_burn "$NAMESPACE" "$res"
    done

    if [[ -n "$DELETE_NAMESPACE" ]]
    then
      kubectl delete ns "$NAMESPACE"
    fi
  done
fi
