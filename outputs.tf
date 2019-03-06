output "ems_address" {
  value = local.EMS_ADDRESS
}

output "cluster_address" {
  value = element(
    concat(
      google_compute_forwarding_rule.elastifile_int_lb.*.ip_address,
      [""],
    ),
    0,
  )
}

