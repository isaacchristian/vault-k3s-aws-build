output "vault_pub_url" {
  description = "The public URL of the Vault server"
  value       = "http://${aws_instance.vault-server.public_ip}:8200"
}

output "node_ip_address" {
  description = "The public URL of the Vault server"
  value       = aws_instance.vault-server.public_ip
}

output "vault_password" {
  description = "The vault terraform user password"
  value       = random_string.vault_pass.id
}