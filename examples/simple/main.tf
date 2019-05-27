
provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

data "aws_region" "usw2" {
  provider = aws.usw2
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

data "aws_region" "use1" {
  provider = aws.use1
}

module "network_plan" {
  source = "github.com/terraformnet/terraform-cidr-addr-plan"

  base_cidr_block = "10.0.0.0/14"
  max_regions     = 4

  regions = [
    {
      name      = data.aws_region.usw2.name
      max_zones = 4
      zones = [
        { name = "a" },
        { name = "b" },
      ]
    },
    {
      name      = data.aws_region.use1.name
      max_zones = 4
      zones = [
        { name = "b" },
        { name = "c" },
      ]
    },
  ]
}

module "vpc_usw2" {
  source = "../.."

  network_plan = module.network_plan
  tags = {
    Name = "vpc-region simple example"
  }

  providers = {
    aws = aws.usw2
  }
}

module "vpc_use1" {
  source = "../.."

  network_plan = module.network_plan
  tags = {
    Name = "vpc-region simple example"
  }

  providers = {
    aws = aws.use1
  }
}

locals {
  vpc_nets = {
    us-west-2 = module.vpc_usw2
    us-east-1 = module.vpc_use1
  }
}

module "peering_usw2" {
  source = "../../modules/peering-mesh"

  region_vpc_networks = local.vpc_nets
  other_region_connections = {
    us-east-1 = module.peering_use1.outgoing_connection_ids
  }

  providers = {
    aws = aws.usw2
  }
}

module "peering_use1" {
  source = "../../modules/peering-mesh"

  region_vpc_networks = local.vpc_nets
  other_region_connections = {
    us-west-2 = module.peering_usw2.outgoing_connection_ids
  }

  providers = {
    aws = aws.use1
  }
}

output "network_plan" {
  value = module.network_plan
}

output "networks" {
  value = local.vpc_nets
}

output "peering_connections" {
  value = {
    us-east-1 = module.peering_use1.all_connection_ids
    us-west-2 = module.peering_usw2.all_connection_ids
  }
}
