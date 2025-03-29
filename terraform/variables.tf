variable "do_token" { type = string }
variable "ssh_key_fingerprint" { type = string }
variable "domain_name" { type = string }
variable "region" { type = string }
variable "droplet_size" { type = string }
variable "db_size" { type = string }
variable "space_name" { type = string }
variable "spaces_access_key" {
  description = "Access key for DigitalOcean Spaces"
  type        = string
}

variable "spaces_secret_key" {
  description = "Secret key for DigitalOcean Spaces"
  type        = string
  sensitive   = true
}
variable "ssh_key_id" {
  description = "ID of the SSH key uploaded to DigitalOcean"
  type        = string
}
