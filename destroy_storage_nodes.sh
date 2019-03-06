#!/bin/bash

set -eux

usage() {
  # NOTE: Keep sorted for easy git merges
  cat << E_O_F
Usage:
  -a account
  -p project
  -r cluster name
  -z comma separated list of zones
E_O_F
}

# NOTE: Keep sorted for easy git merges
while getopts "a:p:r:z:h?" opt; do
    case "$opt" in
    a)  export GOOGLE_APPLICATION_CREDENTIALS=${OPTARG}
        ;;
    p)  PROJECT=${OPTARG}
        ;;
    r)  CLUSTER_NAME=${OPTARG}
        ;;
    z)  IFS=', ' read -r -a ZONES <<< "${OPTARG}"
        ;;
    h|\?)
        usage
        exit 0
        ;;
    esac
done

#delete the nodes with given prefixes
function destroy_nodes {
  NAME_PREFIX="$CLUSTER_NAME-$1-"
 
  for ZONE in "${ZONES[@]}"; do
    VMLIST=$(gcloud compute instances list    \
              --filter="zone:(${ZONE})"       \
              --filter="name:($NAME_PREFIX)"  \
              --project="${PROJECT}"          \
              --format 'value(name)'          \
            )
    if [ ! -z "$VMLIST" ]; then
      gcloud compute instances delete         \
              $VMLIST                         \
              --project="${PROJECT}"          \
              --zone="${ZONE}"                \
              --quiet                         &
    fi
  done
}

destroy_nodes elfs
destroy_nodes ra

exit 0
