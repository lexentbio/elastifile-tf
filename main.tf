variable "DISK_TYPE" {
  default = "persistent"
}

variable "TEMPLATE_TYPE" {
  default = "medium"
}

variable "LB_TYPE" {
  default = "elastifile"
}

variable "VM_CONFIG" {
  default = "4_42"
}

variable "NUM_OF_VMS" {
  default = "3"
}

variable "DISK_CONFIG" {
  default = "5_2000"
}

variable "CLUSTER_NAME" {}

variable "COMPANY_NAME" {}

variable "CONTACT_PERSON_NAME" {}

variable "EMAIL_ADDRESS" {}

variable "IMAGE" {}

variable "SETUP_COMPLETE" {
  default = "false"
}

variable "PASSWORD_IS_CHANGED" {
  default = "false"
}

variable "PASSWORD" {
  default = "changeme"
}

variable "REGION" {
  default = "us-central1"
}

variable "EMS_ZONE" {
  default = "us-central1-a"
}

variable "NETWORK" {
  default = "default"
}

variable "SUBNETWORK" {
  default = "default"
}

variable "PROJECT" {}

variable "CREDENTIALS" {
  default = ""
}

variable "SERVICE_EMAIL" {
  default = ""
}

data "google_compute_default_service_account" "default" {}

locals {
  # Conditionals in terraform are eagerly evaluated. So we set default to dummy value we can check against
  CREDENTIALS   = "${ var.CREDENTIALS == "" ? "${path.module}/blank-credentials" : var.CREDENTIALS }"
  SERVICE_EMAIL = "${ var.SERVICE_EMAIL == "" ? data.google_compute_default_service_account.default.email : var.SERVICE_EMAIL}"
}

variable "USE_PUBLIC_IP" {
  default = true
}

variable "ILM" {
  default = "false"
}

variable "ASYNC_DR" {
  default = "false"
}

variable "LB_VIP" {
  default = "auto"
}

variable "DATA_CONTAINER" {
  default = "DC01"
}

variable "NODES_ZONES" {
  default = "us-central1-a"
}

locals {
  AVAILABILITY_ZONES = "${split(",", var.NODES_ZONES)}"
}

variable "DEPLOYMENT_TYPE" {
  default = "dual"
}

variable "OPERATION_TYPE" {
  default = "none"
}

provider "google" {}

provider "restapi" {
  uri                  = "https://${local.EMS_ADDRESS}/api/"
  insecure             = true
  use_cookies          = true
  write_returns_object = true
  xssi_prefix          = ")]}',"
  headers = {
    Cookie = "${data.external.session.result["value"]}"
  }
}

data "external" "session" {
  program = [
    "${path.module}/create_session.sh",
    "-a",
    "https://${local.EMS_ADDRESS}/api/",
    "-p",
    "changeme",
  ]
}

variable depends_on { default = [], type = "list"}