output "droplet_ip" {
  description = "Public IPv4 address of the Saleor droplet"
  value       = digitalocean_droplet.saleor.ipv4_address
}

output "database_connection_string" {
  description = "PostgreSQL connection string for the Saleor database"
  value       = "postgres://${digitalocean_database_user.saleor.name}:${digitalocean_database_user.saleor.password}@${digitalocean_database_cluster.saleor_db.host}:${digitalocean_database_cluster.saleor_db.port}/${digitalocean_database_db.saleor.name}?sslmode=require"
  sensitive   = true
}

output "space_name" {
  description = "DigitalOcean Space used for storing media"
  value       = digitalocean_spaces_bucket.saleor_media.name
}

output "space_region" {
  description = "Region of the DigitalOcean Space"
  value       = digitalocean_spaces_bucket.saleor_media.region
}
