
resource "aws_vpc_peering_connection" "this" {
  count = length(local.peers)

  vpc_id      = local.region_vpc.id
  peer_region = local.peers[count.index]
  peer_vpc_id = var.region_vpc_networks[local.peers[count.index]].vpc.id
}

resource "aws_vpc_peering_connection_accepter" "this" {
  count = length(local.incoming)

  vpc_peering_connection_id = local.incoming[count.index]
  auto_accept               = true
}
