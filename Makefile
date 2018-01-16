
.DEFAULT=plan

plan:
	terraform plan

apply:
	terraform apply -auto-approve

provision:
	ansible-playbook -i inventory -u buildit playbook.yml

destroy:
	terraform destroy