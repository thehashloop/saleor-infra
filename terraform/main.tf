terraform {
  backend "s3" {
    endpoints                   = { s3 = "https://blr1.digitaloceanspaces.com" }
    bucket                      = "our-terraform-state"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"  # Required but ignored for DigitalOcean
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true         # Needed for non-AWS S3 implementations
  }
  
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
  spaces_access_id  = var.spaces_access_key
  spaces_secret_key = var.spaces_secret_key
}

resource "digitalocean_droplet" "saleor" {
  image  = "ubuntu-20-04-x64"
  name   = "saleor-droplet"
  region = var.region
  size   = var.droplet_size
  ssh_keys = [var.ssh_key_id]
}

resource "digitalocean_database_cluster" "saleor_db" {
  name       = "saleor-db"
  engine     = "pg"
  version    = "13"
  size       = var.db_size
  region     = var.region
  node_count = 1
}

resource "digitalocean_database_db" "saleor" {
  cluster_id = digitalocean_database_cluster.saleor_db.id
  name       = "saleor"
}

resource "digitalocean_database_user" "saleor" {
  cluster_id = digitalocean_database_cluster.saleor_db.id
  name       = "saleor"
}

resource "digitalocean_database_firewall" "saleor_db_firewall" {
  cluster_id = digitalocean_database_cluster.saleor_db.id

  rule {
    type  = "ip_addr"
    value = digitalocean_droplet.saleor.ipv4_address
  }
}

resource "digitalocean_spaces_bucket" "saleor_medias" {
  name   = var.space_name
  region = var.region
}

resource "digitalocean_domain" "default" {
  name = var.domain_name
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.saleor.ipv4_address
}
