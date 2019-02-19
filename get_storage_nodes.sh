#!/bin/sh

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

LOGFILE=storage-nodes.log

echo '{' | tee ${LOGFILE}

for ZONE in "${ZONES[@]}"
do
    gcloud compute instances list \
        --filter="zone:(${ZONE})" \
        --filter="name:(${CLUSTER_NAME}-)" \
        --project="${PROJECT}" \
        --format 'value[terminator=","](selfLink)' \
        | sed "s/\(.*\),$/\"${ZONE}\": \"\\1\",/" \
        | tee -a ${LOGFILE}
done
echo '"DummyRecord": "Because Terraform can not parse json object with extra ,"'
echo '}' | tee -a ${LOGFILE}