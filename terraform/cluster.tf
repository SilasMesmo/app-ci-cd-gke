resource "google_project_service" "enable_gke" {
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_project_service" "enable_resource_manager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_container_cluster" "cluster_1" {
  depends_on = [google_project_service.enable_gke,
                google_project_service.enable_resource_manager,
                google_compute_network.gke_test,
                google_compute_subnetwork.public_subnet
  ]

  name               = "cluster-1"
  location           = var.region
  initial_node_count = 1

  release_channel {
    channel = "STABLE"
  }

  node_locations = ["us-central1-a", "us-central1-b"]

  network    = "projects/${var.project_id}/global/networks/default"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"

  ip_allocation_policy {}

  maintenance_policy {
    recurring_window {
      start_time = "2024-12-28T03:00:18Z"
      end_time   = "2024-12-29T10:00:18Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  enable_shielded_nodes = true

  network_policy {
    provider = "CALICO"
    enabled  = true
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
  }
  monitoring_service = "none"

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

    cluster_autoscaling {
    enabled = false
  }


  master_authorized_networks_config {}
}

resource "google_container_node_pool" "spot_pool" {
  name       = "spot-pool-e2st4"
  cluster    = google_container_cluster.cluster_1.name
  location   = google_container_cluster.cluster_1.location
  node_count = 1
  initial_node_count = 0

  node_config {
    machine_type = "e2-medium"
    image_type   = "COS_CONTAINERD"

    disk_type    = "pd-balanced"
    disk_size_gb = 50

    labels = {
      cluster_name = "cluster1"
      node_pool    = "spot-pool-e2st4"
    }

    metadata = {
      disable-legacy-endpoints = "true"
      cluster_name             = "cluster1"
      node_pool                = "spot-pool-e2st4"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    spot = true
  }


  management {
    auto_repair  = true
    auto_upgrade = true
  }
  max_pods_per_node = 110

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

#  autoscaling {
#    min_node_count = 0
#    max_node_count = 0
#  }

}
