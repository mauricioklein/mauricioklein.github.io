DOCKER_IMAGE := klakegg/hugo
PROJECT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Runs the blog in watch mode
run:
	docker run --rm \
		-v $(PROJECT_PATH):/src \
		-p 1313:1313 \
		-it $(DOCKER_IMAGE) server

.PHONY: run
