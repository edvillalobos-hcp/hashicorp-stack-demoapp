###################
resource "tfe_workspace" "consul-deployment" {
    name = "Consul-Deployment-HashiStack"
    organization = var.TFC_ORGANIZATION
    auto_apply = true
    queue_all_runs = false
    file_triggers_enabled = true
    working_directory = "consul-deployment"
    vcs_repo {
        identifier = "edvillalobos-hcp/hashicorp-stack-demoapp"
        branch = "main"
        oauth_token_id = tfe_oauth_client.github-oauth-client.oauth_token_id
    }

}

resource "tfe_variable" "TFC_ORGANIZATION_CONSUL" {
  key          = "TFC_ORGANIZATION"
  value        = var.TFC_ORGANIZATION
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "list including the public IP address of your machine, in [00.00.00.00/32] form"
}

resource "tfe_variable" "TFC_WORKSPACE_CONSUL" {
  key          = "TFC_WORKSPACE"
  value        = "infrastructure-HashiStack"
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "list including the public IP address of your machine, in [00.00.00.00/32] form"
}

resource "tfe_variable" "HCP_CLIENT_ID_CONSUL" {
  key          = "HCP_CLIENT_ID"
  value        = "my_value_name"
  category     = "env"
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "HCP service principal ID"
}

resource "tfe_variable" "HCP_CLIENT_SECRET_CONSUL" {
  key          = "HCP_CLIENT_SECRET"
  value        = "my_value_name"
  category     = "env"
  sensitive    = true
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "HCP service principal secret"
}

resource "tfe_variable" "AWS_ACCESS_KEY_ID_CONSUL" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = "my_value_name"
  category     = "env"
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "AWS access key ID"
}

resource "tfe_variable" "AWS_SECRET_ACCESS_KEY_CONSUL" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = "my_value_name"
  category     = "env"
  sensitive    = true
  workspace_id = tfe_workspace.consul-deployment.id
  description  = " AWS secret access key"
}

resource "tfe_variable" "AWS_SESSION_TOKEN_CONSUL" {
  key          = "AWS_SESSION_TOKEN"
  value        = "my_value_name"
  category     = "env"
  sensitive    = true
  workspace_id = tfe_workspace.consul-deployment.id
  description  = "If applicable, the token for session"
}