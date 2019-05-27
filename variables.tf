
variable "network_plan" {
  description = "${
    "A network plan map in the structure generated by the terraformnet/addr-plan/cidr module."} ${
    "Each instance of this module creates network objects only for the region associated with its default (unaliased) AWS provider; Instantiate the module multiple times with different providers to populate multiple regions."} ${
    "The region names must correspond with AWS region names and the zone names must be lowercase letters that identify valid VPC availability zones in each region."
  }"

  type = object({
    regions = map(object({
      cidr_block = string
      subnets = map(object({
        zone_name   = string
        cidr_block  = string
        subnet_name = string
      }))
    }))
  })
}

variable "tags" {
  description = "Map of tags to associated with all created objects. At least a Name tag must be present, and its value will be used as a name prefix for some object types this module creates multiple of."

  type = map(string)
}

variable "internet_gateway_subnets" {
  description = "Set of subnet type names to connect to an internet gateway. Use the empty string to select an anonymous subnet type."

  type    = set(string)
  default = [""] // Anonymous subnet type gets internet gateway by default
}

data "aws_region" "current" {}

locals {
  region_name = data.aws_region.current.name
  region_plan = var.network_plan.regions[local.region_name]

  name_tag_base = var.tags["Name"]

  region_subnets = [
    for s in local.region_plan.subnets : {
      zone_name         = s.zone_name
      subnet_name       = s.subnet_name
      cidr_block        = s.cidr_block
      availability_zone = "${local.region_name}${s.zone_name}"
    }
  ]

  subnet_types = sort(toset([
    for s in local.region_subnets : s.subnet_name
  ]))

  internet_gateway_subnets = sort(setintersection(var.internet_gateway_subnets, local.subnet_types))
}
