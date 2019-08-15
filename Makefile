PROJECT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Build the Docker base image
image: Dockerfile
	docker build -t blog $(PROJECT_PATH)

# Opens an interactive console with the Docker container
console:
	docker run --rm \
		-v $(PROJECT_PATH):/app \
		-p 4000:4000 \
		--entrypoint /bin/bash \
		-it blog

# Runs the blog in watch mode
watch:
	docker run --rm \
		-v $(PROJECT_PATH):/app \
		-p 4000:4000 \
		-t blog

.PHONY: image console watch
