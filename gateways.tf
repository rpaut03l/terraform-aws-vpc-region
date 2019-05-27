
resource "aws_internet_gateway" "this" {
  # We only create an internet gateway if there's at least one subnet type
  # to associate it with.
  count = length(local.internet_gateway_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route" "igw" {
  count = length(local.internet_gateway_subnets)

  route_table_id         = local.subnet_route_tables[local.internet_gateway_subnets[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}
