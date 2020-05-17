resource "google_compute_instance" "Elastifile-EMS" {
  name         = var.CLUSTER_NAME
  machine_type = "n1-standard-4"
  zone         = var.EMS_ZONE

  tags = [var.https_firewall_tag]

  boot_disk {
    initialize_params {
      image = "projects/elastifle-public-196717/global/images/${var.IMAGE}"
    }
  }

  network_interface {
    #specify only one:
    #network = google_compute_network.elastifile.name
    subnetwork = google_compute_subnetwork.elastifile.name

    dynamic access_config {
      for_each = var.USE_PUBLIC_IP ? [1] : []

      content {
        // Ephemeral IP
      }
    }
  }

  metadata = {
    ecfs_ems            = "true"
    reference_name      = var.CLUSTER_NAME
    version             = var.IMAGE
    template_type       = var.TEMPLATE_TYPE
    cluster_size        = var.NUM_OF_VMS
    use_load_balancer   = var.LB_TYPE
    disk_type           = var.DISK_TYPE
    disk_config         = var.DISK_CONFIG
    password_is_changed = var.PASSWORD_IS_CHANGED
    setup_complete      = var.SETUP_COMPLETE
    enable-oslogin      = "false"
  }

  metadata_startup_script = <<-SCRIPT
    bash -c sudo\ sed\ -i\ \'/image_project=Elastifile-CI/c\\image_project=elastifle-public-196717\'\ /elastifile/emanage/deployment/cloud/init_cloud_google.sh
    sudo echo type=subscription >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo order_number=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo start_date=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo expiration_date=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo raw_capacity=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo hosts=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo customer_id=unlimited >> /elastifile/emanage/lic/license.gcp.lic
    sudo echo signature=sO9+j5Q/OPBaB+bMViAITGvN6by8vOYUrxNsOBYWZ4yBNqHj02iqpmqk2oxO XI3voLGhg6f0WW2MStEwxv46ia2iOjMZVCi/ekDL4nioYG3L5Sfzs/NMLI+D vlC36rkOfAkMrjkN9z1bRFNYwHCnXf58TC/W7RM6gimzRqpIz14= >> /elastifile/emanage/lic/license.gcp.lic
  SCRIPT


  # specify the GCP project service account to use
  service_account {
    email  = local.SERVICE_EMAIL
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = [tags]
  }

  provisioner "local-exec" {
    command     = "${path.module}/setup_ems.sh -c ${var.TEMPLATE_TYPE} -l ${var.LB_TYPE} -t ${var.DISK_TYPE} -d ${var.DISK_CONFIG} -v ${var.VM_CONFIG} -p ${coalesce(self.network_interface.0.access_config.0.nat_ip, self.network_interface.0.network_ip)} -r ${var.CLUSTER_NAME} -s ${var.DEPLOYMENT_TYPE} -a ${var.NODES_ZONES} -e ${var.COMPANY_NAME} -f ${var.CONTACT_PERSON_NAME} -g ${var.EMAIL_ADDRESS} -i ${var.ILM} -k ${var.ASYNC_DR} -j ${var.LB_VIP}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "${path.module}/destroy_storage_nodes.sh -a ${local.CREDENTIALS} -p ${var.PROJECT} -r ${var.CLUSTER_NAME} -z ${var.NODES_ZONES}"
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}

locals {
  EMS_ADDRESS = coalesce(google_compute_instance.Elastifile-EMS.network_interface.0.access_config.0.nat_ip, google_compute_instance.Elastifile-EMS.network_interface.0.network_ip, "NOT.READY")
}

output "EMS_ADDRESS" {
  value = local.EMS_ADDRESS
}
