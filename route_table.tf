
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  # Remove all routes from the default route table. We don't actually use it,
  # because we create a separate route table for each distinct subnet type
  # instead.
  route = []

  tags = merge(
    var.tags,
    {
      Name = "${local.name_tag_base} (<default>)"
    },
  )
}

resource "aws_route_table" "subnet" {
  count = length(local.subnet_types)

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = (
        local.subnet_types[count.index] != "" ?
        "${local.name_tag_base} (${local.subnet_types[count.index]})" :
        local.name_tag_base
      )
    },
  )
}

locals {
  subnet_route_tables = {
    for i, name in local.subnet_types : name => aws_route_table.subnet[i]
  }
}

resource "aws_route_table_association" "subnet" {
  count = length(local.region_subnets)

  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = local.subnet_route_tables[local.region_subnets[count.index].subnet_name].id
}
