variable "DATA_CONTAINER" {
  default = "DC01"
}

variable "EMS_ADDRESS" {}

variable "PASSWORD" {
  default = "changeme"
}

provider "restapi" {
  uri                  = "https://${var.EMS_ADDRESS}/api/"
  insecure             = true
  use_cookies          = true
  write_returns_object = true
  xssi_prefix          = ")]}',"
  headers = {
    Cookie = data.external.session.result["value"]
  }

}

data "external" "session" {
  program = [
    "${path.module}/create_session.sh",
    "-a",
    "https://${var.EMS_ADDRESS}/api/",
    "-p",
    var.PASSWORD,
  ]
}
