# Configuration
DOCKER_IMAGE := jenkins-dind
DOCKER_CONTAINER := jenkins
DOCKER_NETWORK := jenkins
DOCKER_TAG := $(DOCKER_IMAGE):latest
DOCKER_RUN_FLAGS := --name $(DOCKER_CONTAINER) \
  --memory 1G \
  --restart=on-failure \
  --detach \
  --privileged \
  --network $(DOCKER_NETWORK) \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  $(DOCKER_TAG)
.PHONY: all clean purge rebuild restart get-password exec workspace start-alpine-node help
.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory

##@ Core Operations
start: ## First time setup - Create and start Jenkins
	@echo "🚀 Starting Jenkins setup..."
	@docker build -t $(DOCKER_IMAGE) .
	@docker network create $(DOCKER_NETWORK) 2>/dev/null || true
	@docker run $(DOCKER_RUN_FLAGS)
	@echo "✅ Jenkins is up and running"

clean: ## Stop container and remove network (preserves data)
	@echo "🧹 Cleaning up Jenkins (preserving data)..."
	@docker rm -f $(DOCKER_CONTAINER) 2>/dev/null || true
	@docker network rm $(DOCKER_NETWORK) 2>/dev/null || true
	@echo "✅ Cleanup complete (volumes preserved)"

purge: ## Remove everything including all data (WARNING: Destructive)
	@echo "⚠️  WARNING: This will delete all Jenkins data!"
	@read -p "Are you sure you want to proceed with complete purge? [y/N] " confirmation; \
	if [ "$$confirmation" = "y" ] || [ "$$confirmation" = "Y" ]; then \
		docker rm -f $(DOCKER_CONTAINER) 2>/dev/null || true; \
		docker network rm $(DOCKER_NETWORK) 2>/dev/null || true; \
		docker volume rm jenkins-data jenkins-docker-certs 2>/dev/null || true; \
		echo "🗑️  Purge complete - all data removed"; \
	else \
		echo "❌ Operation cancelled"; \
	fi

rebuild: clean ## Rebuild and restart Jenkins (preserves data)
	@echo "🔄 Rebuilding Jenkins..."
	@docker build -t $(DOCKER_IMAGE) .
	@docker network create $(DOCKER_NETWORK) 2>/dev/null || true
	@docker run $(DOCKER_RUN_FLAGS)
	@echo "✅ Jenkins has been rebuilt and restarted"

restart: purge start ## Complete fresh start (WARNING: Deletes everything)

##@ Utilities
get-password: ## Get the Jenkins initial admin password
	@docker exec $(DOCKER_CONTAINER) cat /var/jenkins_home/secrets/initialAdminPassword

exec: ## Get into the container
	@docker exec -it $(DOCKER_CONTAINER) bash

workspace: ## Enter the container's workspace directory
	@docker exec -it $(DOCKER_CONTAINER) bash -c "cd /var/jenkins_home/workspace && bash"

start-alpine-node: ## Start the alpine container node for jenkins
	@docker run -d --restart=always -p 127.0.0.1:2376:2375 --network jenkins \
		-v /var/run/docker.sock:/var/run/docker.sock \
		alpine/socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock

##@ Help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
