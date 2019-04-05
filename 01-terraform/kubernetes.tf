variable "gce_ssh_user" {
  default = "root"
}
variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/google_compute_engine.pub"
}

variable "gce_zone" {
  type = "string"
}

// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("./service/devops-getup.json")}"
}

resource "google_compute_network" "default" {
  name                    = "kubernetes"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name            = "kubernetes"
  network         = "${google_compute_network.default.name}"
  ip_cidr_range   = "10.240.0.0/24"
}

resource "google_compute_firewall" "internal" {
  name    = "kubernetes-allow-internal"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = [ "10.240.0.0/24", "192.168.0.0/16" ]
}

resource "google_compute_firewall" "external" {
  name    = "kubernetes-allow-external"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "80", "8080", "5000", "5001", "443"]
  }

  source_ranges = [ "0.0.0.0/0" ]
}

resource "google_compute_address" "default" {
  name = "kubernetes"
}

resource "google_compute_instance" "controller" {
  name            = "controller-0"
  machine_type    = "n1-standard-2"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes","controller"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20190326"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.10"

    access_config {
      // Ephemeral IP
    }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config && service sshd restart"
}

resource "google_compute_instance" "worker" {
  count = 2
  name            = "worker-${count.index}"
  machine_type    = "n1-standard-2"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes","worker"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20190326"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.2${count.index}"

    access_config {
      // Ephemeral IP
    }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config && service sshd restart"
}
