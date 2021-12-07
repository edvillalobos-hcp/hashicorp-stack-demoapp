//FTE Provider
terraform {
  required_providers {
    tfe = { }
  }
}

provider "tfe" {
    hostname = var.hostname
    token = var.token
    }

//TFC VCS GitHub
resource "tfe_oauth_client" "github-oauth-client" {
   organization = var.TFC_ORGANIZATION
   api_url          = "https://api.github.com"
   http_url         = "https://github.com"
   oauth_token      = var.oauthtoken
   service_provider = "github"
}
