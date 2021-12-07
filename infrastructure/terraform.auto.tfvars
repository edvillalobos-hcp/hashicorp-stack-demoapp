region                     = "us-west-1"
hcp_region                 = "us-west-1"
name                       = "zero"
hcp_consul_public_endpoint = true
hcp_vault_public_endpoint  = true

tags = {
  Environment = "zero-trust-demo"
  Automation  = "terraform"
  Owner       = "dev"
}
