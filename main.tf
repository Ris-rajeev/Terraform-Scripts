terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = "dop_v1_10c9f65d81c39d46840cea19fcaa7afa4f77635170ca576feb3cd52a084c63e6"
}

resource "digitalocean_ssh_key" "my_ssh_key" {
  name       = "my-ssh-key"
  public_key = file("~/.ssh/id_rsa_digitalOcean.pub") # Path to your public SSH key
}

# Import the SSH key into Terraform

resource "digitalocean_droplet" "my_droplet" {
  name     = "my-droplet"
  region   = "nyc1"             # Choose your desired region
  size     = "s-1vcpu-1gb"      # Choose the desired droplet size
  image    = "ubuntu-20-04-x64" # Choose your desired OS image
  ssh_keys = [digitalocean_ssh_key.my_ssh_key.fingerprint]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa_digitalOcean") # Path to your private SSH key
    timeout     = "4m"                               # Optional: Set the connection timeout
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "docker login --username=risadmin --password=admin1234 git.cloudnsure.com",
      "docker network create redis",
      "docker run -p 6379:6379 -d --name redis --network redis redis",
      "docker pull git.cloudnsure.com/risadmin/suresetu-f:latest",
      "docker run --restart always -d --name suresetu-f -p 30182:80 git.cloudnsure.com/risadmin/suresetu-f:latest",
    ]
  }
}

resource "null_resource" "wait_for_droplet" {
  depends_on = [digitalocean_droplet.my_droplet]

  #   provisioner "local-exec" {
  #     command = "sleep 60" # Wait for 60 seconds for the Droplet to fully start
  #   }
}

output "droplet_ip" {
  value = digitalocean_droplet.my_droplet.ipv4_address
}
