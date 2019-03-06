resource "null_resource" "nodes" {
  triggers = {
    num_of_vms = var.NUM_OF_VMS
  }

  provisioner "local-exec" {
    command     = "${path.module}/update_storage_nodes.sh -n ${var.NUM_OF_VMS} -a ${local.EMS_ADDRESS}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "${path.module}/update_storage_nodes.sh -n 1 -a ${local.EMS_ADDRESS}"
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}

data "external" "storage_nodes" {
  // Get the links of storage node
  program = [
    "${path.module}/get_storage_nodes.sh",
    "-a",
    local.CREDENTIALS,
    "-p",
    var.PROJECT,
    "-r",
    var.CLUSTER_NAME,
    "-z",
    var.NODES_ZONES,
  ]

  depends_on = [null_resource.nodes]
}

