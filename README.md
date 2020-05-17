# Terraform-Elastifile-GCP

Terraform to create, configure and deploy a Elastifile Cloud Filesystem (ECFS) cluster in Google Compute (GCE)

## Note:
Follow the Elastifile Cloud Deployment GCP Installation Guide to make sure ECFS can be successfully deployed in GCE before using this.

## Use:
1. Create password.txt file with a password to use for eManage  (.gitignore skips this file)
2. Specify configuration variables in terraform.tfvars:
- TEMPLATE_TYPE = small, medium, standard, custom. Only use custom in consultation with Elastifile support
- COMPANY_NAME = Name of the company that uses this cluster
- CONTACT_PERSON_NAME = Contact person name
- EMAIL_ADDRESS = Email address of the contact person
- NUM_OF_VMS = Number of ECFS virtual controllers, 3 minimum for small/medium, 6 minimum for standard
- LB_TYPE = none, dns, elastifile, google
- DISK_TYPE = local, ssd, or hdd. Only applies to custom templates
- DISK_CONFIG = [disks per vm]_[disk size in GB] example: "8_375" will create 8, 375GB disks. Only applies to custom templates
- VM_CONFIG = [cpu cores per vm]_[ram per vm] example "20_128" will create 20 CPU, 128GB RAM VMs. Default: "4_42" Only applies to custom templates
- CLUSTER_NAME = Name for ECFS service, no longer than
- EMS_ZONE = EMS Zone
- PROJECT = Project name
- IMAGE = EMS image name
- CREDENTIALS = path to service account credentials .json file if not using
- SERVICE_EMAIL = service account email address
- USE_PUBLIC_IP = true/false. true for creating ems with public IP. false for creating ems with private IP only.
- DEPLOYMENT_TYPE = single, dual, multizone
- NODES_ZONES = list of the zones for the nodes
- SETUP_COMPLETE = true or false
- ILM = true or false
- AsyncDR = true or false

3. Run 'terraform init' then 'terraform apply'


## Components:

**google_ecfs.tf**
Main terraform configuration file.

**create_vheads.sh**
Bash script to configure Elastifile eManage (EMS) Server via Elastifile REST API. EMS will deploy cluster of ECFS virtual controllers (vheads). Called as null_provider from google_ecfs.tf

Note: REST calls are HTTPS (443) to the public IP of EMS. Ensure GCP project firewall rules allow 443 (ingress) from wherever this Terraform template is run.

**destroy_vheads.sh**
Bash script to query and delete multiple GCE instances and network resources simultaneously. Called as null_provider destroy from google_ecfs.tf

**add_vheads.sh**
Bash script to query and add multiple GCE instances and network resources simultaneously. Called as script from update_vheads.sh

**remove_vheads.sh**
Bash script to query and remove multiple GCE instances and network resources simultaneously. Called as script from update_vheads.sh

**update_vheads.sh**
Bash script to query, add/remove multiple GCE instances, update the google iLB and network resources simultaneously. Called as null_provider from google_ecfs.tf

**create_google_ilb.sh**
Bash script to create all the neccesary resources for the google iLB simultaneously. Called as null_provider from google_ecfs.tf

**update_google_ilb.sh**
Bash script to query and change the google iLB configurations after adding/removing nodes. Called as script from update_vheads.sh

**destroy_google_ilb.sh**
Bash script to query and delete all the google iLB resources simultaneously. Called as null_provider destroy from google_ecfs.tf


**password.txt**
Plaintext file with EMS password

## Troubleshooting:
** *.log files**
Output of all scripts and REST commands

**/elastifile/log/**
Log directory from EMS

## Known Issues:
Custom template configurations are not officially supported by Elastifile.
Shared VPC configuration is partially supported, and will cot configure the Elastifile LB.

## This version supports Elastifile Ver 3.x with the following:
- Single replication for SSD PD device configurations.
- Dual replication for all configurations
- Multizone cluster, needs 3 zones in the same region.
- Adding and removing nodes from a live cluster, by changing the SETUP_COMPLETE to true, and modifing the NUM_OF_VMS to the requested number.
- deploying with google iLB, with dynamic support to add/remove nodes.
- deploying with elastifile LB,  with dynamic support to add/remove nodes.
- Public IP, true/flase support.
- Custom configuration of the cluster.
- Full Destroy 
- ILM configuration
- AsyncDR configuration

## This version supports Elastifile Ver 2.7.x with the following:
- Dual replication for all configurations
- Adding nodes from a live cluster, by changing the SETUP_COMPLETE to true, and modifing the NUM_OF_VMS to the requested number. 
*** Removing nodes is not supported for version 2.7.5.x ***
- deploying with google iLB, with dynamic support to add/remove nodes.
- deploying with elastifile LB,  with dynamic support to add/remove nodes.
- Public IP, true/flase support.
- Custom configuration of the cluster.
- Full Destroy
