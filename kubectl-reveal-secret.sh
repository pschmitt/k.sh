#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") [--context CONTEXT] [-n NAMESPACE] SECRET [KEY]"
}

get_current_ns() {
  local ctx="${ctx:-$(kubectl current-context)}"
  kubectl --context "$ctx" config view --minify --output 'jsonpath={..namespace}'
}

list_secrets() {
  local ns="${ns:-$(get_current_ns)}"
  local ctx="${ctx:-$(kubectl current-context)}"

  kubectl -n "$ns" get secret -o name | xargs -I {} basename {}
}

reveal_secret() {
  local ns ctx

  while [[ -n "$*" ]]
  do
    case "$1" in
      --context)
        ctx="$2"
        shift 2
        ;;
      -n|--namespace)
        ns="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  # Default to current context
  ctx=${ctx:-$(kubectl config current-context)}

  local secret="$1"
  local key="$2"

  if [[ -z "$secret" ]]
  then
    {
      echo "Missing secret."
      usage
      echo -e "\nAvaible secrets:"
      ctx="$ctx" ns="$ns" list_secrets
    } >&2
    return 2
  fi

  ns="${ns:-$(ctx="$ctx" get_current_ns)}"

  if [[ -z "$key" ]]
  then
    kubectl --context "$ctx" -n "$ns" get secrets -o json "$secret" | \
      jq -r '.data | to_entries[] | .key + " " + (.value | @base64d)'
  else
    # Only show plaintext value of the requested key
    kubectl --context "$ctx" -n "$ns" get secrets -o json "$secret" | \
      jq -r --arg key "$key" '.data[$key] | @base64d'
  fi
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
