variable "TFC_ORGANIZATION" {
    default = "Demo-Org-EV"
}
variable "hostname" {
    default = "app.terraform.io"
    sensitive = true
}
variable "token"{}
variable "oauthtoken"{} 

variable "database_password" {}
variable "client_cidr_block" {}