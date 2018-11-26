
org_name=Sewa Rural Old
#org_admin_name=adminsr
#adminsr should belong to 'sewa rural old' to deploy to prod properly
org_admin_name=FIX_PROD_ADMIN_SR_USER

#============commonMakefile=====================================

poolId:=
clientId:=
password:=
port:= $(if $(port),$(port),8021)
server:= $(if $(server),$(server),http://localhost)
server_url:=$(server):$(port)
username:=$(if $(username),$(username),$(org_admin_name))
su:=$(shell id -un)

define _curl
	echo "$(username) @ $(server_url)/$(2) $(1) $(3)"
	curl -X $(1) $(server_url)/$(2) -d @$(3)  \
		-H "Content-Type: application/json"  \
		-H "USER-NAME: $(username)"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

dev:
	$(eval server_url:=http://localhost:8021)

prod:
	$(eval poolId:=$(OPENCHS_PROD_USER_POOL_ID))
	$(eval clientId:=$(OPENCHS_PROD_APP_CLIENT_ID))
	$(eval server_url:= https://server.openchs.org:443)

staging:
	$(eval poolId:=$(OPENCHS_STAGING_USER_POOL_ID))
	$(eval clientId:=$(OPENCHS_STAGING_APP_CLIENT_ID))
	$(eval server_url:= https://staging.openchs.org:443)

by_admin:
	$(eval username:=admin)

by_org_admin:
	$(eval username:=$(org_admin_name))

auth:
	$(if $(poolId),$(eval token:=$(shell node scripts/token.js $(poolId) $(clientId) $(username) $(password))))

create_org:
	psql -U$(su) openchs < create_organisation.sql

deploy_admin_user: by_admin
	@$(call _curl,POST,users,users/admin-user.json)

deploy_test_users:
	@$(call _curl,POST,users,users/test-users.json)

# <refdata>
_get_non_coded_concepts=node -e "console.log(JSON.stringify(require('$(1)').filter(x=>x.dataType!=='Coded')));"

define _deploy_non_coded_concept
	$(eval tmpfile:=$(shell mktemp))
	$(call _get_non_coded_concepts,$(1)) > $(tmpfile)
	echo "non-coded $(1)"
	$(call _curl,POST,concepts,$(tmpfile))
	rm $(tmpfile)
endef

deploy_non_coded_concepts:
	@$(if $(shell command -v node 2> /dev/null),\
		$(foreach file,$(shell find . -iname '*concepts.json'),\
			$(call _deploy_non_coded_concept,$(file));))

deploy_concepts: deploy_non_coded_concepts
	@$(foreach file,$(shell find . -iname '*concepts.json'),$(call _curl,POST,concepts,$(file));)

deploy_refdata: deploy_concepts
	@$(foreach item,locations catchments programs encounterTypes,\
		$(if $(shell ls "$(item).json" 2> /dev/null),$(call _curl,POST,$(item),$(item).json);))

	@$(foreach file,$(shell find . -iname 'operationalPrograms.json'),$(call _curl,POST,operationalPrograms,$(file));)
	@$(foreach file,$(shell find . -iname 'operationalEncounterTypes.json'),$(call _curl,POST,operationalEncounterTypes,$(file));)

	@$(foreach file,$(shell find . -iname '*form.json'),$(call _curl,POST,forms,$(file));)
	@$(foreach file,$(shell find . -iname '*deletions.json'),$(call _curl,DELETE,forms,$(file));)
	@$(foreach file,$(shell find . -iname '*additions.json'),$(call _curl,PATCH,forms,$(file));)

	@$(if $(shell ls formMappings.json 2> /dev/null),$(call _curl,POST,formMappings,formMappings.json))

deploy_checklists:
	@$(foreach file,$(shell find . -iname '*checklistConcepts.json'),$(call _curl,POST,concepts,$(file));)
	@$(foreach file,$(shell find . -iname '*checklistForm.json'),$(call _curl,POST,forms,$(file));)
	@$(foreach file,$(shell find . -iname '*checklistDetail.json'),$(call _curl,POST,checklistDetail,$(file));)
# </refdata>

# <deploy>
_deploy: deploy_refdata deploy_checklists deploy_rules##

deploy_rules: ##
	@$(if $(shell ls index.js 2> /dev/null),node index.js "$(server_url)" "$(token)" "$(username)")
# </deploy>

deps:
	npm i

deploy_admin_user_dev: dev by_admin deploy_admin_user

deploy_admin_user_prod: prod by_admin auth deploy_admin_user #password=

deploy_admin_user_staging: staging by_admin auth deploy_admin_user #password=

deploy_test_users_prod: prod by_admin auth deploy_test_users #password=

deploy_test_users_staging: staging by_admin auth deploy_test_users #password=

deploy_users_dev: dev by_admin deploy_admin_user deploy_test_users

deploy_rules_dev: dev by_org_admin deploy_rules

deploy_rules_prod: prod by_org_admin auth deploy_rules #password=

deploy_rules_staging: staging by_org_admin auth deploy_rules #password=

deploy_dev: dev by_org_admin _deploy

deploy_prod: prod by_org_admin auth _deploy #password=

deploy_staging: staging by_org_admin auth _deploy #password=

deploy_dev_as_staging: staging deploy_dev #password=

deploy_dev_as_prod: prod deploy_dev #password=
