#
# Directories.
#
# Full directory of where the Makefile resides
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GO_INSTALL := ./hack/go_install.sh
# output
OUTPUT_DIR := $(abspath $(ROOT_DIR)/_output)
OUTPUT_BIN_DIR := $(OUTPUT_DIR)/bin
OUTPUT_TOOLS_DIR := $(OUTPUT_DIR)/tools

export PATH := $(abspath $(OUTPUT_BIN_DIR)):$(abspath $(OUTPUT_TOOLS_DIR)):$(PATH)

#
# Binaries.
#
# Note: Need to use abspath so we can invoke these from subdirectories
KK_VER := v4.0.0-alpha.1
KK_BIN := kk
KK_GEN := $(abspath $(OUTPUT_TOOLS_DIR)/$(KK_BIN))
KK_PKG := github.com/kubesphere/kubekey/v4/cmd/kk

#
# Deploy.
#
# Note: Deploy prow in cluster
DEPLOY_SKIP_TAGS ?= qingcloud
DEPLOY_WORK_DIR ?= $(OUTPUT_DIR)
deploy_tag_command := $(foreach t,$(DEPLOY_TAGS),--tags $(t) )
deploy_skip_tag_command := $(foreach t,$(DEPLOY_SKIP_TAGS),--skip-tags $(t) )


.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[0-9A-Za-z_-]+:.*?##/ { printf "  \033[36m%-45s\033[0m %s\n", $$1, $$2 } /^\$$\([0-9A-Za-z_-]+\):.*?##/ { gsub("_","-", $$1); printf "  \033[36m%-45s\033[0m %s\n", tolower(substr($$1, 3, length($$1)-7)), $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


## --------------------------------------
## Hack / Tools
## --------------------------------------

##@ hack/tools:
.PHONY: $(KK_BIN)
$(KK_BIN): ## Build kubekey from tools folder.
	@if [ ! -f $(OUTPUT_TOOLS_DIR)/$(KK_BIN) ]; then \
		GOBIN=$(OUTPUT_TOOLS_DIR) $(GO_INSTALL) $(KK_PKG) $(KK_BIN) $(KK_VER);\
	fi


.PHONY: deploy
#deploy: $(KK_BIN) ## deploy prow in a cluster
deploy: ## deploy prow in a cluster
	@$(OUTPUT_TOOLS_DIR)/$(KK_BIN) run .deploy/playbooks/deploy.yaml --inventory .deploy/inventory/inventory.yaml --work-dir $(DEPLOY_WORK_DIR) \
		$(deploy_tag_command) $(deploy_skip_tag_command) \
		--set github_appid="$(GITHUB_APPID)" --set github_token="$(GITHUB_TOKEN)" --set github_cert="$(GITHUB_CERT)"
