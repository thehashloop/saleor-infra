terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Size of the droplet"
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "db_size" {
  description = "Size of the database cluster"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "space_name" {
  description = "Name of the Space"
  type        = string
}

resource "digitalocean_droplet" "saleor" {
  image  = "ubuntu-20-04-x64"
  name   = "saleor-droplet"
  region = var.region
  size   = var.droplet_size
  ssh_keys = [var.ssh_key_fingerprint]
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

resource "digitalocean_spaces_bucket" "saleor_media" {
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