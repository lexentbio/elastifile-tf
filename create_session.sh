#!/bin/sh

set -eux

usage() {
  # NOTE: Keep sorted for easy git merges
  cat << E_O_F
Usage:
  -a API Endpoint
  -p password
E_O_F
}

# NOTE: Keep sorted for easy git merges
while getopts "a:p:r:z:h?" opt; do
    case "$opt" in
    a)  API_ENDPOINT=${OPTARG}
        ;;
    p)  PASSWORD=${OPTARG}
        ;;
    h|\?)
        usage
        exit 0
        ;;
    esac
done

curl -k -D - -H "Content-Type: application/json" -X POST -d '{"user": {"login":"admin","password":"'$PASSWORD'"}}' $API_ENDPOINT/sessions | \
awk -F ";" 'BEGIN{printf "{ \"value\": \""; ORS=";";}/Set-Cookie/{print substr($1, 13)}END{ORS="";print "\"}"}'