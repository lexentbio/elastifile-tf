resource "google_compute_instance_group" "storage_nodes" {
  count = var.LB_TYPE == "google" ? length(local.AVAILABILITY_ZONES) : 0

  name = "${var.CLUSTER_NAME}-${local.AVAILABILITY_ZONES[count.index]}"
  zone = local.AVAILABILITY_ZONES[count.index]

  instances = split(
    ",",
    lookup(data.external.storage_nodes.result, element(local.AVAILABILITY_ZONES, count.index), ""),
  )

  # TODO: tf-0.12 will come with dynamic blocks which will allow these instance groups to be set on backend service directly.
  #       Until then we'll have to use the provisioners to add and remove them from the backend service.
  # TODO: tf-0.12 will come with dynamic blocks which will allow these instance groups to be set on backend service directly.
  #       Until then we'll have to use the provisioners to add and remove them from the backend service.
  provisioner "local-exec" {
    command = "gcloud compute backend-services add-backend ${google_compute_region_backend_service.elastifile_int_lb[0].name} --instance-group ${self.name} --instance-group-zone ${self.zone} --project ${var.PROJECT} --region ${var.REGION}"

    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = local.CREDENTIALS
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "gcloud compute backend-services remove-backend ${google_compute_region_backend_service.elastifile_int_lb[0].name} --instance-group ${self.name} --instance-group-zone ${self.zone} --project ${var.PROJECT} --region ${var.REGION}"

    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = local.CREDENTIALS
    }
  }
}

resource "google_compute_health_check" "elastifile_tcp_health_check" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name = "${var.CLUSTER_NAME}-tcp-health-check"

  tcp_health_check {
    port = "111"
  }
}

resource "google_compute_region_backend_service" "elastifile_int_lb" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name          = "${var.CLUSTER_NAME}-int-lb"
  health_checks = google_compute_health_check.elastifile_tcp_health_check[*].self_link
  protocol      = "TCP"

  lifecycle {
    ignore_changes = [backend]
  }
}

resource "google_compute_forwarding_rule" "elastifile_int_lb" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name                  = "${var.CLUSTER_NAME}-int-lb"
  network               = var.NETWORK
  subnetwork            = var.SUBNETWORK
  backend_service       = google_compute_region_backend_service.elastifile_int_lb[0].self_link
  load_balancing_scheme = "INTERNAL"
  ports                 = [111, 2049, 644, 4040, 4045]
}

resource "google_compute_firewall" "elastifile_allow_internal_lb" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name    = "${var.CLUSTER_NAME}-allow-internal-lb"
  network = var.NETWORK

  allow {
    protocol = "tcp"
  }

  source_ranges = [data.google_compute_subnetwork.elastifile.ip_cidr_range]
  target_tags   = ["elastifile-storage-node"]
}

resource "google_compute_firewall" "elastifile_storage_management" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name    = "${var.CLUSTER_NAME}-storage-management"
  description             = "Elastifile Storage Management firewall rules"
  network = var.NETWORK

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["22", "53", "80", "8080", "443", "10014-10017"]
  }

  allow {
    protocol = "udp"
    ports = ["53", "123", "6667"]
  }

  source_ranges = [data.google_compute_subnetwork.elastifile.ip_cidr_range]
  source_tags   = ["elastifile-storage-node", "elastifile-replication-node", "elastifile-clients"]
  target_tags = ["elastifile-management-node"]
}

resource "google_compute_firewall" "elastifile_storage_service" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name    = "${var.CLUSTER_NAME}-storage-service"
  description             = "Elastifile Storage Service firewall rules"
  network = var.NETWORK

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["22", "111", "443", "2049", "644", "4040", "4045", "12121", "10015-10017", "8000-9224", "32768-60999"]
  }

  allow {
    protocol = "udp"
    ports = ["111", "2049", "644", "4040", "4045", "6667", "8000-9224", "32768-60999"]
  }

  source_ranges = [data.google_compute_subnetwork.elastifile.ip_cidr_range]
  source_tags = ["elastifile-management-node", "elastifile-clients"]
  target_tags   = ["elastifile-storage-node", "elastifile-replication-node"]
}

resource "google_compute_firewall" "elastifile_allow_health_check" {
  count = var.LB_TYPE == "google" ? 1 : 0

  name    = "${var.CLUSTER_NAME}-allow-health-check"
  network = var.NETWORK

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["elastifile-storage-node"]
}

data "google_compute_subnetwork" "elastifile" {
  name = var.SUBNETWORK
}

