PROJECT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

docker: Dockerfile
	docker build -t blog $(PROJECT_PATH)

console:
	docker run --rm -v $(PROJECT_PATH):/app -p 4000:4000 -it --entrypoint "/bin/bash" blog

watch:
	docker run --rm -v $(PROJECT_PATH):/app -p 4000:4000 -t blog
