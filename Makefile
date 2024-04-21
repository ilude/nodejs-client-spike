# https://docs.docker.com/develop/develop-images/build_enhancements/
# https://www.docker.com/blog/faster-builds-in-compose-thanks-to-buildkit-support/
export DOCKER_BUILDKIT := 1
export DOCKER_SCAN_SUGGEST := false
export COMPOSE_DOCKER_CLI_BUILD := 1

ifneq (,$(wildcard .env))
	include .env
	export
endif

.PHONY: run build

run: build
	docker run -it --rm alpine-node-tor

bash:
	docker-compose run --build --rm alpine-node-tor bash -l 

build:
	docker build -t alpine-node-tor .

