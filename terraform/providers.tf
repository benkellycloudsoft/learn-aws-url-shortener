# This tells terraform which provider and user our project depends on
terraform {
    required_providers {
        aws = { # aws is the provider we want to use
            source = "hashicorp/aws" # The namespace of the provider
            version = ">= 6.7.0" # The minimum version
        }
    }
}

# This tells tf how to authenticate with AWS
provider "aws" {
    region = var.region # Use the region variable we defined in variables.tf
    profile = var.profile # Use the profile variable we defined in variables.tf
}