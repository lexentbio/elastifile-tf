resource "restapi_object" "data_container" {
  path      = "/data_containers"
  data      = "${jsonencode(local.data_container_data)}"
  force_new = ["${var.DATA_CONTAINER}"]
}

resource "restapi_object" "share" {
  path = "/exports"
  data = "${jsonencode(local.share_data)}"
  force_new = ["${restapi_object.data_container.id}"]
}

locals {
  data_container_data = {
    name        = "${var.DATA_CONTAINER}"
    dedup       = 0
    compression = 1

    soft_quota = {
      bytes = "${1000*1024*1024*1024}"
    }

    hard_quota = {
      bytes = "${1000*1024*1024*1024}"
    }

    policy_id       = 1
    dir_uid         = 0
    dir_gid         = 0
    dir_permissions = "755"
    data_type       = "general_purpose"
    namespace_scope = "global"
  }

  share_data = {
    data_container_id       = "${restapi_object.data_container.id}"
    name                    = "root"
    path                    = "/"
    user_mapping            = "remap_all"
    uid                     = 0
    gid                     = 0
    access_permission       = "read_write"
    client_rules_attributes = []
    namespace_scope         = "global"
    data_type               = "general_purpose"
  }
}
