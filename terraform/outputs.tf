output "droplet_ip" {
  description = "IP address of the Saleor server"
  value       = digitalocean_droplet.saleor.ipv4_address
}

output "db_host" {
  description = "Database host"
  value       = digitalocean_database_cluster.saleor_db.host
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = digitalocean_database_cluster.saleor_db.port
  sensitive   = true
}

output "db_user" {
  description = "Database user"
  value       = digitalocean_database_user.saleor.name
  sensitive   = true
}

output "db_password" {
  description = "Database password"
  value       = digitalocean_database_user.saleor.password
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = digitalocean_database_db.saleor.name
  sensitive   = true
}

output "database_url" {
  description = "Full PostgreSQL connection URL"
  value       = "postgres://${digitalocean_database_user.saleor.name}:${digitalocean_database_user.saleor.password}@${digitalocean_database_cluster.saleor_db.host}:${digitalocean_database_cluster.saleor_db.port}/${digitalocean_database_db.saleor.name}"
  sensitive   = true
}
