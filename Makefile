
PULL ?= IfNotPresent

build: ## Builds the starter pack
	go build -i github.com/crunchydata/pgo-osb/cmd/pgo-osb

test: ## Runs the tests
	go test -v $(shell go list ./... | grep -v /vendor/ | grep -v /test/)

linux: ## Builds a Linux executable
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
	go build -o pgo-osb --ldflags="-s" github.com/crunchydata/pgo-osb/cmd/pgo-osb
main:
	go install pgo-osb.go

image: main
	cp $(GOBIN)/pgo-osb .
	sudo --preserve-env buildah bud --squash -f $(OSB_ROOT)/$(OSB_BASEOS)/Dockerfile.pgo-osb.$(OSB_BASEOS) -t $(OSB_IMAGE_PREFIX)/pgo-osb:$(OSB_IMAGE_TAG) $(OSB_ROOT)
	sudo --preserve-env buildah push $(OSB_IMAGE_PREFIX)/pgo-osb:$(OSB_IMAGE_TAG) docker-daemon:$(OSB_IMAGE_PREFIX)/pgo-osb:$(OSB_IMAGE_TAG)

push:
	docker push $(OSB_IMAGE_PREFIX)/pgo-osb:$(OSB_IMAGE_TAG)


deploy:
	cd deploy && ./deploy.sh

clean: ## Cleans up build artifacts
	rm -f pgo-osb
	rm -f pgo-osb-linux
	rm -f image/pgo-osb

provision: ## Provisions a service instance
	expenv -f manifests/service-instance.yaml | kubectl create -f -
deprovision:
	kubectl delete serviceinstance testinstance
provision2: ## Provisions a service instance
	expenv -f manifests/service-instance2.yaml | kubectl create -f -
deprovision2:
	kubectl delete serviceinstance testinstance2

setup:
	go get github.com/blang/expenv

bind: ## Creates a binding
	expenv -f manifests/service-binding.yaml | kubectl create -f -
bind2: ## Creates a binding
	expenv -f manifests/service-binding2.yaml | kubectl create -f -

help: ## Shows the help
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
        awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ''

.PHONY: deploy build test linux image clean push deploy-helm deploy-openshift create-ns provision bind help
