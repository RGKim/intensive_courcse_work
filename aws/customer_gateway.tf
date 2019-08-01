# resource "aws_customer_gateway" "group1_customer_gw" {
#   ip_address = ""
#   type       = "ipsec.1"

#   tags = {
#     Name = "main-customer-gateway"
#   }
# }

# resource "aws_vpn_gateway" "vpn_gw_group1" {
#   vpc_id = "${aws_vpc.dev.id}"
#   tags = {
#     Name = "main_group1"
#   }
# }

# resource "aws_vpn_connection" "main_group1" {
#   vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw_group1.id}"
#   customer_gateway_id = "${data.aws_customer_gateway.group1_customer_gw.id}"
#   type                = "${data.aws_customer_gateway.group1_customer_gw.type}"
#   static_routes_only  = true
# }

# resource "aws_vpn_connection_route" "azure_group1" {
#   destination_cidr_block = "${azurerm_subnet.subnet.address_prefix}"
#   vpn_connection_id      = "${aws_vpn_connection.main_group1.id}"
# }