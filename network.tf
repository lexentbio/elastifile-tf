resource "google_compute_network" "elastifile" {
  name                    = var.CLUSTER_NAME
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "elastifile" {
  name                     = var.CLUSTER_NAME
  network                  = google_compute_network.elastifile.self_link
  ip_cidr_range            = "10.129.0.0/20"
  private_ip_google_access = "true"
}