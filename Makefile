# Configuration
DOCKER_IMAGE := jenkins
DOCKER_CONTAINER := jenkins-blueocean
DOCKER_NETWORK := jenkins
DOCKER_TAG := myjenkins-blueocean:2.414.2
DOCKER_BUILD_FLAGS := -t $(DOCKER_IMAGE)
DOCKER_RUN_FLAGS := --name $(DOCKER_CONTAINER) --restart=on-failure --detach \
  --network $(DOCKER_NETWORK) --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro $(DOCKER_TAG)

.PHONY: all build network run get-password start clean help
.DEFAULT_GOAL := help

# Suppress Entering/Leaving print output from make
MAKEFLAGS += --no-print-directory

##@ Jenkins Setup
build: ## Build the Jenkins BlueOcean Docker image
	@echo "🚀 Building Docker image: $(DOCKER_IMAGE)"
	docker build $(DOCKER_BUILD_FLAGS) .

network: ## Create the Docker network 'jenkins'
	@echo "🔧 Creating Docker network: $(DOCKER_NETWORK)"
	docker network create $(DOCKER_NETWORK) || echo "Network $(DOCKER_NETWORK) already exists"

run: ## Run the Jenkins BlueOcean container
	@echo "🏃‍♂️ Starting Jenkins container: $(DOCKER_CONTAINER)"
	docker run $(DOCKER_RUN_FLAGS)

get-password: ## Get the Jenkins initial admin password
	@echo "🔑 Retrieving Jenkins initial admin password"
	docker exec $(DOCKER_CONTAINER) cat /var/jenkins_home/secrets/initialAdminPassword

start: build network run ## Build, create network, and run Jenkins in one go
	@echo "🎉 Jenkins is up and running"

##@ Maintenance
clean: ## Stop and remove the Jenkins container and network
	@echo "🧹 Cleaning up Jenkins container and network"
	docker rm -f $(DOCKER_CONTAINER) || echo "Container $(DOCKER_CONTAINER) does not exist"
	docker network rm $(DOCKER_NETWORK) || echo "Network $(DOCKER_NETWORK) does not exist"

##@ Documentation
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
