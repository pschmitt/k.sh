#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") [-n NAMESPACE] SECRET"
}

get_current_ns() {
  kubectl config view --minify --output 'jsonpath={..namespace}'
}

list_opaque_secrets() {
  local ns="${ns:-$(get_current_ns)}"

  kubectl -n "$ns" get secret -o json | \
    jq -r '.items[] | select(.type == "Opaque").metadata.name'
}

reveal_secret() {
  local ns

  while [[ -n "$*" ]]
  do
    case "$1" in
      -n|--namespace)
        ns="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  local secret="$1"

  if [[ -z "$secret" ]]
  then
    {
      echo "Missing secret."
      usage
      echo -e "\nAvaible secrets:"
      ns="$ns" list_opaque_secrets
    } >&2
    return 2
  fi

  ns="${ns:-$(get_current_ns)}"

  kubectl -n "$ns" get secrets -o json "$secret" | \
    jq -r '.data | to_entries[] | .key + " " + (.value | @base64d)'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  case "$1" in
    help|--help|-h)
      usage
      exit 0
      ;;
    *)
      reveal_secret "$@"
      ;;
  esac
fi
