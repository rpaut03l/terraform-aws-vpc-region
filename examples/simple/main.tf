
provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

module "network_plan" {
  source = "github.com/terraformnet/terraform-cidr-addr-plan"

  base_cidr_block = "10.0.0.0/14"
  max_regions     = 4

  regions = [
    {
      name      = "us-west-2"
      max_zones = 4
      zones = [
        { name = "a" },
        { name = "b" },
      ]
    },
    {
      name      = "us-east-1"
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

output "network_plan" {
  value = module.network_plan
}

output "results" {
  value = {
    us-west-2 = module.vpc_usw2
    us-east-1 = module.vpc_use1
  }
}
