
resource "aws_vpc" "this" {
  cidr_block = local.region_plan.cidr_block

  tags = var.tags
}

resource "aws_subnet" "this" {
  # FIXME: Using for_each for this would be much better, once Terraform supports
  # it, so that we can use the subnet names to identify each instance and thus
  # not upset the existing instances when a new one is added.
  count = length(local.region_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.region_subnets[count.index].cidr_block
  availability_zone = local.region_subnets[count.index].availability_zone

  tags = merge(
    var.tags,
    {
      Name = (
        local.region_subnets[count.index].subnet_name != "" ?
        "${local.name_tag_base} (${local.region_subnets[count.index].availability_zone}, ${local.region_subnets[count.index].subnet_name})" :
        "${local.name_tag_base} (${local.region_subnets[count.index].availability_zone})"
      )
    },
  )
}
