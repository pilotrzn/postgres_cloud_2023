terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}


resource "yandex_compute_instance" "vm-1" {
  count = 1
  name = "postgresql-${count.index}"
  hostname= "postgresql-${count.index}"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = "fd8firhksp7daa6msfes"
      size = 20
    }
  }

  network_interface {
    subnet_id = "e9b9kc3n7e36nq2l08jq"
    nat       = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }

connection {
  type        = "ssh"
  user        = "konstantin"
  private_key = "${file(var.ssh_key_private)}"
  host = self.network_interface[0].nat_ip_address
}

provisioner "remote-exec" {
  inline = [
    "sudo apt update",
    "sudo apt install -y mc"]
  }

provisioner "remote-exec" {
  script = "postgresql.sh"
  }

}