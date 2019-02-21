output "ems_address" {
    value = "${local.EMS_ADDRESS}"
}

output "cluster_address" {
    value = "${var.LB_TYPE == "google" ? google_compute_forwarding_rule.elastifile_int_lb.0.ip_address : ""}"
}