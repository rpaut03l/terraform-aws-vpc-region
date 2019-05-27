
locals {
  outgoing_connection_ids = tomap({
    for c in aws_vpc_peering_connection.this : c.peer_region => c.id
  })

  incoming_connection_ids = tomap({
    for source, m in var.other_region_connections : source => m[local.region_name]
    if source != local.region_name && ! contains(local.peers, source)
  })
}

output "outgoing_connection_ids" {
  value = local.outgoing_connection_ids
}

output "incoming_connection_ids" {
  value = local.incoming_connection_ids
}

output "all_connection_ids" {
  value = merge(
    local.incoming_connection_ids,
    local.outgoing_connection_ids,
  )
}
