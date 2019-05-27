
output "vpc" {
  value = {
    id         = aws_vpc.this.id
    cidr_block = aws_vpc.this.cidr_block
  }
}

output "subnets" {
  value = toset([
    for i, s in local.region_subnets : {
      id                = aws_subnet.this[i].id
      cidr_block        = aws_subnet.this[i].cidr_block
      availability_zone = aws_subnet.this[i].availability_zone
      route_table_id    = local.subnet_route_tables[local.region_subnets[i].subnet_name].id
    }
  ])
}

output "route_tables" {
  value = {
    for k, v in local.subnet_route_tables : k => {
      id = v.id
    }
  }
}
