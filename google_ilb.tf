data "external" "storage_nodes" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  // Get the links of storage node
  program = [
    "${path.module}/get_storage_nodes.sh",
    "-a",
    "${local.CREDENTIALS}",
    "-p",
    "${var.PROJECT}",
    "-r",
    "${var.CLUSTER_NAME}",
    "-z",
    "${var.NODES_ZONES}",
  ]

  depends_on = ["null_resource.cluster"]
}

resource "google_compute_instance_group" "webservers" {
  count = "${var.LB_TYPE == "google" ? length(local.AVAILABILITY_ZONES) : 0}"

  name = "${var.CLUSTER_NAME}-${local.AVAILABILITY_ZONES[count.index]}"
  zone = "${local.AVAILABILITY_ZONES[count.index]}"

  instances = ["${split(",", data.external.storage_nodes.result[element(local.AVAILABILITY_ZONES, count.index)])}"]

  # TODO: tf-0.12 will come with dynamic blocks which will allow these instance groups to be set on backend service directly.
  #       Until then we'll have to use the provisioners to add and remove them from the backend service.
  provisioner "local-exec" {
    command = "gcloud compute backend-services add-backend ${google_compute_region_backend_service.elastifile_int_lb.name} --instance-group ${self.name} --instance-group-zone ${self.zone} --project ${var.PROJECT} --region ${var.REGION}"

    environment {
      GOOGLE_APPLICATION_CREDENTIALS = "${local.CREDENTIALS}"
    }
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "gcloud compute backend-services remove-backend ${google_compute_region_backend_service.elastifile_int_lb.name} --instance-group ${self.name} --instance-group-zone ${self.zone} --project ${var.PROJECT} --region ${var.REGION}"

    environment {
      GOOGLE_APPLICATION_CREDENTIALS = "${local.CREDENTIALS}"
    }
  }
}

resource "google_compute_health_check" "elastifile_tcp_health_check" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  name = "${var.CLUSTER_NAME}-tcp-health-check"

  tcp_health_check {
    port = "111"
  }
}

resource "google_compute_region_backend_service" "elastifile_int_lb" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  name          = "${var.CLUSTER_NAME}-int-lb"
  health_checks = ["${google_compute_health_check.elastifile_tcp_health_check.self_link}"]
  protocol      = "TCP"
}

resource "google_compute_forwarding_rule" "elastifile_int_lb" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  name                  = "${var.CLUSTER_NAME}-int-lb"
  network               = "${var.NETWORK}"
  subnetwork            = "${var.SUBNETWORK}"
  backend_service       = "${google_compute_region_backend_service.elastifile_int_lb.self_link}"
  load_balancing_scheme = "INTERNAL"
  ports                 = [111, 2049, 644, 4040, 4045]
}

resource "google_compute_firewall" "elastifile_allow_internal_lb" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  name    = "${var.CLUSTER_NAME}-allow-internal-lb"
  network = "${var.NETWORK}"

  allow {
    protocol = "tcp"
  }

  source_ranges = ["${data.google_compute_subnetwork.elastifile.ip_cidr_range}"]
  target_tags   = ["elastifile-storage-node"]
}

resource "google_compute_firewall" "elastifile_allow_health_check" {
  count = "${var.LB_TYPE == "google" ? 1 : 0}"

  name    = "${var.CLUSTER_NAME}-allow-health-check"
  network = "${var.NETWORK}"

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["elastifile-storage-node"]
}

data "google_compute_subnetwork" "elastifile" {
  name = "${var.SUBNETWORK}"
}
