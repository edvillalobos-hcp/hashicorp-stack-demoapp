fmt:
	cd vault && terraform fmt
	cd consul-deployment && terraform fmt
	cd boundary-configuration && terraform fmt
	cd boundary-deployment && terraform fmt
	cd infrastructure && terraform fmt
	cd kubernetes && terraform fmt
	terraform fmt

kubeconfig:
	aws eks --region $(shell cd infrastructure && terraform output -raw region) update-kubeconfig \
		--name $(shell cd infrastructure && terraform output -raw eks_cluster_name)

db-token:
	boundary authenticate password --keyring-type=none -login-name=edriosv \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_products_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
		
db-config:
	boundary connect postgres -username=postgres --keyring-type=none \
	-token  \
	-target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_postgres) -- -d products -f database-service/products.sql
		
configure-db:
	boundary authenticate password -login-name=edriosv \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_products_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
	boundary connect postgres -username=postgres -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_postgres) -- -d products -f database-service/products.sql

configure-consul: kubeconfig
	consul acl token update -id \
		$(shell consul acl token list -format json |jq -r '.[] | select (.Policies[0].Name == "terminating-gateway-terminating-gateway-token") | .AccessorID') \
    	-policy-name database-write-policy -merge-policies -merge-roles -merge-service-identities
	kubectl apply -f consul-deployment/terminating_gateway.yaml

ops-token:
	@boundary authenticate password -login-name=ops \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_operations_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id) \
		--keyring-type=none

ops-ssh:
	@boundary connect ssh -username=ec2-user -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_eks)\
		--keyring-type=none -token at_kpMMAJ6pmL_s1N9ieWaKkUvFy3Tdki59HuYZxYRd57joiX4xRdAthWSjionrUtv3dCE5bWUWgaJWm9L3ut35G15cHcybwVxmNWi4tLkg3zbPrN8JBdcG4QbmwMY1SFPDucsHVV -- -i ~/.ssh/id_rsa

ssh-operations:
	@boundary authenticate password -login-name=ops \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_operations_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id) \
		--keyring-type=pass
	boundary connect ssh -username=ec2-user -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_eks)\
		--keyring-type=pass -- -i ~/.ssh/id_rsa

ssh-products:
	@boundary authenticate password -login-name=appdev \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_products_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
	boundary connect ssh -username=ec2-user -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_eks) -- -i ~/.ssh/id_rsa

postgres-operations:
	@boundary authenticate password -login-name=ops \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_operations_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
	boundary connect postgres -username=postgres -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_postgres)

postgres-products:
	@boundary authenticate password -login-name=appdev \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_products_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
	boundary connect postgres -username=postgres -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_postgres) -- -d products

frontend-products:
	@boundary authenticate password -login-name=appdev \
		-password $(shell cd boundary-configuration && terraform output -raw boundary_products_password) \
		-auth-method-id=$(shell cd boundary-configuration && terraform output -raw boundary_auth_method_id)
	boundary connect -target-id \
		$(shell cd boundary-configuration && terraform output -raw boundary_target_frontend)

configure-application:
	kubectl apply -f application/

get-application:
	kubectl get svc frontend -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"

clean-infrastructure:
	terraform state rm 'module.eks.kubernetes_config_map.aws_auth[0]'

clean-application:
	kubectl delete -f application/

clean-vault:
	vault lease revoke -force -prefix database/creds

clean-consul:
	kubectl delete -f consul-deployment/terminating_gateway.yaml

taint:
	cd consul-deployment && terraform taint hcp_consul_cluster_root_token.token

clean: clean-application clean-vault clean-consul taint

vault-commands:
	vault list sys/leases/lookup/database/creds/product
	kubectl exec -it $(shell kubectl get pods -l="app=product" -o name) -- cat /vault/secrets/conf.json

db-commands:
	psql -h 127.0.0.1 -p 62079 -U postgres -d products -f database-service/products.sql