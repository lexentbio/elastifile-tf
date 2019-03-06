#!/usr/bin/env bash
set -u

# function code from https://gist.github.com/cjus/1047794 by itstayyab
function jsonValue() {
KEY=$1
 awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${KEY}'\042/){print $(i+1)}}}' | tr -d '"'| tr '\n' ','
}

usage() {
  cat << E_O_F
Usage:
Parameters:
  -n number of enode instances (cluster size): eg 3
  -a IP address
Examples:
  ./update_vheads.sh -n 2 -a 10.100.10.1
E_O_F
  exit 1
}

#variables
SESSION_FILE=session.txt
PASSWORD=`cat password.txt | cut -d " " -f 1`
LOG="update_vheads.log"

[[ -z "$PASSWORD" ]] && PASSWORD=changeme

while getopts "h?:n:a:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    n)  NUM_OF_VMS=${OPTARG}
        ;;
    a)  EMS_ADDRESS=${OPTARG}
        ;;
    esac
done

#capture computed variables
echo "EMS_ADDRESS: ${EMS_ADDRESS}" | tee ${LOG}
echo "NUM_OF_VMS: ${NUM_OF_VMS}" | tee -a ${LOG}

#establish https session
function establish_session {
  echo -e "Establishing https session..\n" | tee -a ${LOG}
  curl -k -D ${SESSION_FILE} -H "Content-Type: application/json" -X POST -d '{"user": {"login":"admin","password":"'$1'"}}' https://${EMS_ADDRESS}/api/sessions >> ${LOG} 2>&1
}

# Kickoff a create enode instances job
function create_instances {
  echo -e "Creating ${1} ECFS instances\n" | tee -a ${LOG}
  result=$(curl -k -b ${SESSION_FILE} -H "Content-Type: application/json" -X POST -d '{"instances":'${1}',"async":true,"auto_start":true}' https://${EMS_ADDRESS}/api/hosts/create_instances)
  echo $result | tee -a ${LOG}
  taskid=$(echo $result | jsonValue id | sed s'/[,]$//')
  echo "taskid: $taskid" | tee -a ${LOG}
}


# Kickoff a create enode instances job
function delete_instances {
  echo -e "Delete ${NUM_OF_VMS} ECFS instances\n" | tee -a ${LOG}
  result=$(curl -k -b ${SESSION_FILE} -H "Content-Type: application/json" -X POST -d '{"instances":'$1',"async":true}' "https://${EMS_ADDRESS}/api/hosts/delete_instances")
  echo $result |tee -a ${LOG}
  taskid=$(echo $result | jsonValue id | sed s'/[,]$//')
  echo "taskid: $taskid" | tee -a ${LOG}
}

# Function to check running job status
function job_status {
  while true; do
    echo -e "checking job status" | tee -a ${LOG}
    STATUS=`curl -k -s -b ${SESSION_FILE} --request GET --url "https://${EMS_ADDRESS}/api/control_tasks/$taskid" | grep status | cut -d , -f 7 | cut -d \" -f 4`
    echo -e  "$taskid : ${STATUS} " | tee -a ${LOG}
    if [[ ${STATUS} == "" ]]; then
      echo -e "$taskid Re_establish_session..\n" | tee -a ${LOG}
      establish_session ${PASSWORD}
      continue
    elif [[ ${STATUS} == "success" ]]; then
      echo -e "$taskid Complete! \n" | tee -a ${LOG}
      break
    elif  [[ ${STATUS} == "error" ]]; then
      echo -e "$taskid Failed. Exiting..\n" | tee -a ${LOG}
      exit 1
    fi
    sleep 10
  done
}

function update_vheads {
  PRE_IPS=$(curl -k -b ${SESSION_FILE} -H "Content-Type: application/json" https://${EMS_ADDRESS}/api/enodes/ 2> /dev/null | jsonValue external_ip | sed s'/[,]$//')
  PRE_NUM_OF_VMS=$(echo $PRE_IPS | awk -F"," '{print NF}')
  echo "PRE_NUM_OF_VMS: ${PRE_NUM_OF_VMS}" | tee -a ${LOG}
  if [[ ${NUM_OF_VMS} > ${PRE_NUM_OF_VMS} ]]; then
    let NUM=${NUM_OF_VMS}-${PRE_NUM_OF_VMS}
    create_instances $NUM
  else
    let NUM=${PRE_NUM_OF_VMS}-${NUM_OF_VMS}
    delete_instances $NUM
  fi

  # job_status
}

#MAIN
establish_session ${PASSWORD}
update_vheads



