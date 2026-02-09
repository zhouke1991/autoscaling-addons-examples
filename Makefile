.PHONY: help build run clean docker-build docker-push

# Variables
APP_NAME=autocaling-example
GIT_COMMIT_SHORT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT_COUNT=$(shell git rev-list --count HEAD 2>/dev/null || echo "0")
IMAGE_TAG=$(GIT_COMMIT_COUNT)-$(GIT_COMMIT_SHORT)
DOCKER_IMAGE=$(APP_NAME):$(IMAGE_TAG)
DOCKER_REGISTRY?=YOUR_DOCKER_REGISTRY
K8S_NAMESPACE?=default

help: ## Display this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Current image tag: $(IMAGE_TAG)"

build: ## Build the Go application
	@echo "Building $(APP_NAME)..."
	go build -o bin/$(APP_NAME) .
	@echo "Build complete: bin/$(APP_NAME)"

run: ## Run the application locally
	@echo "Running $(APP_NAME)..."
	go run main.go

deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

version: ## Show current version/tag information
	@echo "Git commit: $(GIT_COMMIT_SHORT)"
	@echo "Commit count: $(GIT_COMMIT_COUNT)"
	@echo "Image tag: $(IMAGE_TAG)"
	@echo "Full image: $(DOCKER_IMAGE)"

docker-build: ## Build Docker image with git-based tag
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .
	@echo "Docker image built: $(DOCKER_IMAGE)"

docker-push: docker-build ## Push Docker image to registry
	@echo "Tagging and pushing to registry..."
	docker tag $(DOCKER_IMAGE) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	@echo "Image pushed: $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)"

docker-run: docker-build ## Run Docker container locally
	@echo "Running Docker container..."
	docker run -p 8080:8080 --rm --name $(APP_NAME) $(DOCKER_IMAGE)

load-test: ## Run a simple load test (requires hey or wrk)
	@echo "Running load test..."
	@if command -v hey >/dev/null 2>&1; then \
		echo "Using hey for load testing..."; \
		hey -z 60s -c 50 -q 10 http://localhost:8080/api; \
	elif command -v wrk >/dev/null 2>&1; then \
		echo "Using wrk for load testing..."; \
		wrk -t4 -c50 -d60s http://localhost:8080/api; \
	else \
		echo "Please install 'hey' or 'wrk' for load testing"; \
		echo "  macOS: brew install hey"; \
		echo "  Linux: go install github.com/rakyll/hey@latest"; \
	fi

metrics: ## Open metrics endpoint in browser (macOS)
	@echo "Opening metrics endpoint..."
	@open http://localhost:8080/metrics || echo "Visit http://localhost:8080/metrics"

all: clean deps build docker-build ## Build everything
