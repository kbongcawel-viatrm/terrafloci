terraform {
  source = "../../../modules/s3-bucket"
}

locals {
  region      = get_env("AWS_DEFAULT_REGION", "us-west-1")
  endpoint    = get_env("AWS_ENDPOINT_URL", "http://localhost:4566")
  bucket_name = get_env("TF_VAR_bucket_name", "terrafloci-local-s3-example")
}

remote_state {
  backend = "local"
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 6.0"
        }
      }
    }

    provider "aws" {
      region                      = "${local.region}"
      access_key                  = "${get_env("AWS_ACCESS_KEY_ID", "test")}"
      secret_key                  = "${get_env("AWS_SECRET_ACCESS_KEY", "test")}"
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true
      s3_use_path_style           = true

      endpoints {
        s3 = "${local.endpoint}"
      }
    }
  EOF
}

inputs = {
  bucket_name   = local.bucket_name
  force_destroy = true
  tags = {
    ManagedBy = "Terragrunt"
    Workspace = "terrafloci-local"
  }
}