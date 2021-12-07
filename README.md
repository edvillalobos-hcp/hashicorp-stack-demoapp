# HashiCorp Demo Application with Boundary, Consul, & Vault on Kubernetes

This is the HashiCorp demo application on Amazon EKS. It incorporates the following
tools:

- Terraform 1.0.3
- HashiCorp Cloud Platform (HCP) Consul 1.9.8
- HashiCorp Cloud Platform (HCP) Vault 1.7.3
- Boundary 0.6.0

![Architecture diagram with HashiCorp Cloud Platform Consul and Vault connecting to an AWS EKS cluster and Boundary](./assets/diagram.png)

Each folder contains a few different configurations.

- Terraform Modules
  - `boundary-deployment/`: This is a __local__ Terraform module because it includes
    the Boundary binary and an SSH key. It is referenced by `infrastructure/`.

- Terraform Configurations
  - `infrastructure/`: All the infrastructure to run the system.
     - VPC (3 private subnets, 3 public subnets)
     - Boundary cluster (controllers, workers, and AWS RDS PostgreSQL database)
     - AWS Elastic Kubernetes Service cluster
     - AWS RDS (PostgreSQL) database for demo application
     - HashiCorp Virtual Network (peered to VPC)
     - HCP Consul
     - HCP Vault
   - `boundary-configuration`: Configures Boundary with two projects, one for operations
      and the other for development teams.
   - `consul-deployment/`: Deploys a Consul cluster via Helm chart.
   - `vault-deployment/`: Deploy a Vault cluster via Helm chart.

- Kubernetes
   - `application/`: Deploys the HashiCorp Demo Application (AKA HashiCups)

## Prerequisites

1. Terraform Cloud
1. AWS Account
1. HashiCorp Cloud Platform account
   1. You need access to HCP Consul and Vault.
   1. Create a [service principal](https://portal.cloud.hashicorp.com/access/service-principals)
      for the HCP Terraform provider.
1. `jq` installed
1. Install HashiCorp Boundary and an SSH key to the `boundary-deployment/bin` directory.
   1. Download Boundary to `boundary-deployment/bin/boundary`.
      ```shell
      cd boundary-deployment/bin
      curl https://releases.hashicorp.com/boundary/0.6.0/boundary_0.6.0_linux_amd64.zip -o boundary.zip
      unzip boundary.zip
      rm boundary.zip
      ```
   1. Add an SSH key named `id_rsa` to `boundary-deployment/bin`. You can optionally add a passphrase.
      ```shell
      $ ssh-keygen -t rsa

      Enter file in which to save the key (~/.ssh/id_rsa): boundary-deployment/bin/id_rsa
      ```
1. Fork this repository.

## Deploy infrastructure.

> Note: When you run this, you might get the error `Provider produced inconsistent final plan`.
> This is because we're using [`default_tags`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags).
> Re-run the plan and apply to resolve the error.

First, set up the Terraform workspace.

1. Create a new Terraform workspace.
1. Choose "Version control workflow".
1. Connect to GitHub.
1. Choose your fork of this repository.
1. Name the workpsace `infrastructure`.
1. Select the "Advanced Options" dropdown.
1. Use the working directory `infrastructure`.
1. Select "Create workspace".

Next, configure the workspace's variables.

1. Variables should include:
   - `private_ssh_key` (sensitive): base64 encoded SSH Key for Boundary SSH
   - `database_password` (sensitive): password for Amazon RDS PostgreSQL database for application.
      __SAVE THIS PASSWORD! YOU'LL NEED IT TO LOG IN LATER!__
   - `client_cidr_block` (sensitive): public IP address of your machine, in `00.00.00.00/32` form.
      You get it by running `curl ifconfig.me` in your terminal.

1. Environment Variables should include:
   - `HCP_CLIENT_ID`: HCP service principal ID
   - `HCP_CLIENT_SECRET` (sensitive): HCP service principal secret
   - `AWS_ACCESS_KEY_ID`: AWS access key ID
   - `AWS_SECRET_ACCESS_KEY` (sensitive): AWS secret access key
   - `AWS_SESSION_TOKEN` (sensitive): If applicable, the token for session

If you have additional variables you want to customize, including __region__, make sure to update them in
the `infrastructure/terraform.auto.tfvars` file.

Finally, start a new plan and apply it. It can take more than 15 minutes to provision!

## Configure Boundary

First, set up the Terraform workspace.

1. Create a new Terraform workspace.
1. Choose "Version control workflow".
1. Connect to GitHub.
1. Choose your fork of this repository.
1. Name the workpsace `boundary-configuration`.
1. Select the "Advanced Options" dropdown.
1. Use the working directory `boundary-configuration`.
1. Select "Create workspace".

Next, configure the workspace's variables. This Terraform configuration
retrieves a set of variables using `terraform_remote_state` data source.

1. Variables should include:
   - `tfc_organization`: your Terraform Cloud organization name
   - `tfc_workspace`: `infrastructure`

1. Environment Variables should include:
   - `AWS_ACCESS_KEY_ID`: AWS access key ID
   - `AWS_SECRET_ACCESS_KEY` (sensitive): AWS secret access key
   - `AWS_SESSION_TOKEN` (sensitive): If applicable, the token for session


Queue to plan and apply. This creates an organization with two scopes:
- `core_infra`, which allows you to SSH into EKS nodes
- `product_infra`, which allows you to access the PostgreSQL database

Only `product` users will be able to access `product_infra`.
`operations` users will be able to access both `core_infra`
and `product_infra`.

To use Boundary, use your terminal in the top level of this repository.

1. Set the `BOUNDARY_ADDR` environment variable to the Boundary endpoint.
   ```shell
   export BOUNDARY_ADDR=$(cd boundary-configuration && terraform output -raw boundary_endpoint)
   ```

1. Use the example command in top-level `Makefile` to SSH to the EKS nodes as the operations team.
   ```shell
   make ssh-operations
   ```

1. Go to the Boundary UI and examine the "Sessions". You should get an active session
   in the Boundary list because you accessed the EKS node over SSH.
   ![List of active sessions in Boundary UI, one session listed as active and another listed as terminated](./assets/boundary_sessions.png)

## Add Coffee Data to Database

To add data, you need to log into the PostgreSQL database. However, it's on a private
network. You need to use Boundary to proxy to the database.

1. Set the `PGPASSWORD` environment variable to the database password you
   defined in the `infrastructure` Terraform workspace.
   ```shell
   export PGPASSWORD=<password that you set in infrastructure workspace>
   ```

1. Run the following commands to log in and load data into the `products`
   database.
   ```shell
   make configure-db
   ```

1. If you try to log in as a user of the `products` team, you can print
   out the tables.
   ```shell
   make postgres-products
   ```

## Configure Consul

> Note: When you run this, the Helm release for Consul will fail.
> You need to run a separate command to configure the terminating
> gateway with an ACL. Once you run the command, run another plan
> and apply. The Helm chart will successfully flag as released.

First, set up the Terraform workspace.

1. Create a new Terraform workspace.
1. Choose "Version control workflow".
1. Connect to GitHub.
1. Choose your fork of this repository.
1. Name the workpsace `consul-deployment`.
1. Select the "Advanced Options" dropdown.
1. Use the working directory `consul-deployment`.
1. Select "Create workspace".

Next, configure the workspace's variables. This Terraform configuration
retrieves a set of variables using `terraform_remote_state` data source.

1. Variables should include:
   - `tfc_organization`: your Terraform Cloud organization name
   - `tfc_workspace`: `infrastructure`

1. Environment Variables should include:
   - `HCP_CLIENT_ID`: HCP service principal ID
   - `HCP_CLIENT_SECRET` (sensitive): HCP service principal secret
   - `AWS_ACCESS_KEY_ID`: AWS access key ID
   - `AWS_SECRET_ACCESS_KEY` (sensitive): AWS secret access key
   - `AWS_SESSION_TOKEN` (sensitive): If applicable, the token for session

1. Queue to plan and apply. This deploys Consul clients and a terminating gateway
   via the Consul Helm chart to the EKS cluster to join the HCP Consul servers.
   It also registers the database as an external service to Consul.

1. Update the [terminating gateway](https://www.consul.io/docs/k8s/connect/terminating-gateways#update-terminating-gateway-acl-token-if-acls-are-enabled)
   with a write policy to the database. You need to run this outside of Terraform in your CLI!
   ```shell
   export CONSUL_HTTP_ADDR=$(cd infrastructure && terraform output -raw hcp_consul_public_address)
   export CONSUL_HTTP_TOKEN=$(cd consul-deployment && terraform output -raw hcp_consul_token)
   make configure-consul
   ```

> Note: To delete, you will need to run `make clean-consul` before destroying the infrastructure with Terraform.

## Configure Vault

First, set up the Terraform workspace.

1. Create a new Terraform workspace.
1. Choose "Version control workflow".
1. Connect to GitHub.
1. Choose your fork of this repository.
1. Name the workpsace `vault-deployment`.
1. Select the "Advanced Options" dropdown.
1. Use the working directory `vault-deployment`.
1. Select "Create workspace".

Next, configure the workspace's variables. This Terraform configuration
retrieves a set of variables using `terraform_remote_state` data source.

1. Variables should include:
   - `tfc_organization`: your Terraform Cloud organization name
   - `tfc_workspace`: `infrastructure`

1. Environment Variables should include:
   - `HCP_CLIENT_ID`: HCP service principal ID
   - `HCP_CLIENT_SECRET` (sensitive): HCP service principal secret
   - `AWS_ACCESS_KEY_ID`: AWS access key ID
   - `AWS_SECRET_ACCESS_KEY` (sensitive): AWS secret access key
   - `AWS_SESSION_TOKEN` (sensitive): If applicable, the token for session

Terraform will set up [Kubernetes authentication method](https://www.vaultproject.io/docs/auth/kubernetes)
and [PostgreSQL database secrets engine](https://www.vaultproject.io/docs/secrets/databases/postgresql).

> Note: To delete, you will need to run `make clean-vault` before destroying the infrastructure with Terraform.


## Deploy Example Application

To deploy the example application, run `make configure-application`.

> Note: To delete, you will need to run `make clean-application`.

You can check if everything by checking the pods in Kubernetes.

```shell
$ kubectl get pods

NAME                                                          READY   STATUS    RESTARTS   AGE
consul-46zp9                                                  1/1     Running   0          5m12s
consul-connect-injector-webhook-deployment-79b8b7986d-zsc5f   1/1     Running   0          5m12s
consul-controller-64cf857cdc-d9vq6                            1/1     Running   0          5m12s
consul-cq56l                                                  1/1     Running   0          5m12s
consul-hmfr4                                                  1/1     Running   0          5m12s
consul-terminating-gateway-5f5d9947cf-k8m8h                   2/2     Running   0          5m12s
consul-webhook-cert-manager-5745cbb9d-w7qqk                   1/1     Running   0          5m12s
frontend-99765b95f-r8z8j                                      3/3     Running   0          3m46s
product-589b95f9f5-p5ncz                                      4/4     Running   0          3m45s
public-86b5578cd-29k4s                                        3/3     Running   0          3m45s
vault-agent-injector-57dc4886cd-7sfnf                         1/1     Running   0          63m
```

Port forward the `frontend` service to [http://localhost:8080](http://localhost:8080).

```shell
kubectl port-forward svc/frontend 8080:80
```

You'll get a UI with a "Packer-Spiced Latte".

## Use Boundary to access the application UI

 Make sure you set your environment variables in your terminal.

```shell
bash set_terminal.sh
```

Rather than port-forward the service with Kubernetes, you can authenticate to Boundary
to access the application UI over its internal load balancer.

1. Get the internal load balancer's DNS name. If you try to access the load balancer from your machine,
   you won't be able to because it is an internal one!
   ```shell
   export FRONTEND_DNS=$(kubectl get svc frontend -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
   ```

1. Define a variable for `products_frontend_address` in `boundary-configuration/terraform.auto.tfvars`.
   ```shell
   products_frontend_address=<set to FRONTEND_DNS environment variable>
   ```

1. Queue to plan and apply. This adds a target to the `products_infra` scope in Boundary.

1. Use Boundary to proxy to the frontend UI's load balancer. Access the UI on the `Address` and `Port`
   fields.
   ```shell
   $ make frontend-products

   # omitted
   Proxy listening information:
   Address:             127.0.0.1
   Port:                61169
   ```

You'll get a UI with a "Packer-Spiced Latte".

## Credits

- The module for Boundary is based on the [Boundary AWS Reference Architecture](https://github.com/hashicorp/boundary-reference-architecture/tree/main/deployment)
  with slight modifications.

- The demo application comes from the [HashiCorp Demo Application](https://github.com/hashicorp-demoapp).