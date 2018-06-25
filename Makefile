# <makefile>
# Objects: refdata, package
# Actions: clean, build, deploy
help:
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
	    IFS=$$'#' ; \
	    help_split=($$help_line) ; \
	    help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    printf "%-30s %s\n" $$help_command $$help_info ; \
	done
# </makefile>


port:= $(if $(port),$(port),8021)
server:= $(if $(server),$(server),http://localhost)

su:=$(shell id -un)
org_name:=$(if $(org_name),$(org_name),Sewa Rural)

define _curl
	curl -X $(1) $(server):$(port)/$(2) -d $(3)  \
		-H "Content-Type: application/json"  \
		-H "ORGANISATION-NAME: $(org_name)"  \
		-H "AUTH-TOKEN: $(token)" \
	@echo
	@echo
endef

create_org:
	psql -U$(su) openchs < create_organisation.sql

## <refdata>
deploy_refdata: ## Creates reference data by POSTing it to the server
	$(call _curl,POST,catchments,@catchments.json)
	$(call _curl,POST,concepts,@concepts.json)
	$(call _curl,POST,forms,@registrationForm.json)
	$(call _curl,POST,operationalModules,@operationalModules.json)
	$(call _curl,DELETE,forms,@mother/enrolmentDeletions.json)
	$(call _curl,PATCH,forms,@mother/enrolmentAdditions.json)

## </refdata>

deploy: deploy_refdata

dev_deploy:
	org_name='Sewa Rural Old' make deploy
