# VPC Peering Connection
resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.vpc_id_requester
  peer_vpc_id = var.vpc_id_accepter

  auto_accept = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-peering"
    }
  )
}

# Add routes from requester VPC to accepter VPC
resource "aws_route" "requester_to_accepter" {
  count                     = length(var.requester_route_table_ids)
  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# Add routes from accepter VPC to requester VPC
resource "aws_route" "accepter_to_requester" {
  count                     = length(var.accepter_route_table_ids)
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}
