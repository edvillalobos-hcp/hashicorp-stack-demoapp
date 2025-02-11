//infrastructure Workspace
resource "tfe_workspace" "infrastructure" {
    name = "infrastructure-HashiStack"
    organization = var.TFC_ORGANIZATION
    auto_apply = false
    queue_all_runs = false
    file_triggers_enabled = true
    working_directory = "infrastructure"
    vcs_repo {
        identifier = "edvillalobos-hcp/hashicorp-stack-demoapp"
        branch = "main"
        oauth_token_id = tfe_oauth_client.github-oauth-client.oauth_token_id
    }

}

#Infrastructure Workspace Variables
# resource "tfe_variable" "test" {
#   key          = "my_key_name"
#   value        = "my_value_name"
#   category     = "terraform"
#  sensitive    = true
#   workspace_id = tfe_workspace.infrastructure.id
#   description  = "a useful description"
# }

resource "tfe_variable" "private_ssh_key" {
  key          = "private_ssh_key"
  value        = "current-value"
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.infrastructure.id
  description  = "base64 encoded SSH Key for Boundary SSH"
}

resource "tfe_variable" "database_password" {
  key          = "database_password"
  value        = var.database_password
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.infrastructure.id
  description  = "password for Amazon RDS PostgreSQL database for application"
}

resource "tfe_variable" "client_cidr_block" {
  key          = "client_cidr_block"
  value        = var.client_cidr_block
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.infrastructure.id
  description  = "list including the public IP address of your machine, in [00.00.00.00/32] form"
}

#Infrastructure Workspace Env Variables
# resource "tfe_variable" "test" {
#   key          = "my_key_name"
#   value        = "my_value_name"
#   category     = "env"
#   workspace_id = tfe_workspace.infrastructure.id
#   description  = "a useful description"
# }

