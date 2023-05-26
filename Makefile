SHELL:=bash

test_suites = advanced

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	@make git-hooks

.PHONY: git-hooks
git-hooks: ## Set up hooks in .githooks
	@git submodule update --init .githooks ; \
	git config core.hooksPath .githooks \

.PHONY: test
test: ## Build, test, and destroy default scenario with Kitchen Terraform
	@ci/scripts/run-kitchen.sh --action test --args "${test_suites} --destroy=always"

.PHONY: build
build: ## Build default scenario with Kitchen Terraform
	@ci/scripts/run-kitchen.sh --action converge --args ${test_suites}

.PHONY: verify
verify: ## Build default scenario with Kitchen Terraform
	@ci/scripts/run-kitchen.sh --action verify --args ${test_suites}

.PHONY: destroy
destroy: ## Build default scenario with Kitchen Terraform
	@ci/scripts/run-kitchen.sh --action destroy --args ${test_suites}

.PHONY: debug
debug: ## Debug hybrid-mode scenario with Kitchen Terraform
	@ci/scripts/run-kitchen.sh --action debug --args ${test_suites}

