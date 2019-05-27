
variable "region_vpc_networks" {
  description = "Map from region names to VPC objects as defined by the main vpc-region module. Each module instance creates peering pairs only where the initiator is the region associated with the default (unaliased) aws provider, so instantiate this module once per region to complete the mesh."

  type = map(object({
    vpc = object({
      id         = string
      cidr_block = string
    })
    subnets = set(object({
      id             = string
      cidr_block     = string
      route_table_id = string
    }))
  }))
}

variable "other_region_connections" {
  description = "Map of maps giving the ids of the peering connections of all other regions participating in the mesh. This is used to accept incoming peering connections; if it isn't set, no peering connections with the target region can be accepted."

  type    = map(map(string))
  default = {}
}

data "aws_region" "current" {}

locals {
  region_name            = data.aws_region.current.name
  region_net             = var.region_vpc_networks[local.region_name]
  region_vpc             = local.region_net.vpc
  region_subnets         = local.region_net.subnets
  region_route_table_ids = sort(toset(local.region_subnets.*.route_table_id))

  pairs = toset([
    for pair in setproduct(keys(var.region_vpc_networks), keys(var.region_vpc_networks)) :
    sort(pair) if pair[0] != pair[1]
  ])
  peers = sort([for pair in local.pairs : pair[1] if pair[0] == local.region_name])

  incoming = [
    for source, m in var.other_region_connections : m[local.region_name]
    if source != local.region_name && ! contains(local.peers, source)
  ]

  outgoing_connection_ids = tomap({
    for c in aws_vpc_peering_connection.this : c.peer_region => c.id
  })
  incoming_connection_ids = tomap({
    for source, m in var.other_region_connections : source => m[local.region_name]
    if source != local.region_name && ! contains(local.peers, source)
  })
  all_connection_ids = merge(
    local.incoming_connection_ids,
    local.outgoing_connection_ids,
  )

  routes_per_table = concat(
    [
      for region, conn_id in local.all_connection_ids : {
        destination_cidr_block    = var.region_vpc_networks[region].vpc.cidr_block
        vpc_peering_connection_id = conn_id
      }
    ],
  )
  routes = [
    for pair in setproduct(local.routes_per_table, local.region_route_table_ids) : {
      route_table_id            = pair[1]
      destination_cidr_block    = pair[0].destination_cidr_block
      vpc_peering_connection_id = pair[0].vpc_peering_connection_id
    }
  ]
}
