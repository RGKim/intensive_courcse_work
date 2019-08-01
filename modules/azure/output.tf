output "_instructions" {
  value = "This output contains plain text. You can add variables too."
}

output "public_dns" {
  value = "${azurerm_public_ip.tf-guide-pip.fqdn}"
}

output "App_Server_URL" {
  value = "http://${azurerm_public_ip.tf-guide-pip.fqdn}"
}