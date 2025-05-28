# Criar a VPC gke-test
resource "google_compute_network" "gke_test" {
  name                    = "gke-test"
  auto_create_subnetworks = false
}

# Criar subnets pública e privada na VPC gke-test
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.gke_test.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.gke_test.id
}
