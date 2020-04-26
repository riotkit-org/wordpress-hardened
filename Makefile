SUDO=sudo
SHELL=/bin/bash
RIOTKIT_UTILS_VERSION=2.2.0
CI_UTILS_BIN=./.helpers/ci-utils-${RIOTKIT_UTILS_VERSION}/bin

TAG_PRESENT := $(shell [[ "${TAG}" != "" ]] || echo "present")

ifeq ($(TAG_PRESENT), present)
	SELECTED_TAG := latest-build
else
	SELECTED_TAG := ${TAG}
endif

all: build

VERSION=5.4-php7.3

build: ## Build image
	${SUDO} docker build . \
		--build-arg WP_VERSION=${VERSION} \
		--build-arg RIOTKIT_IMAGE_VERSION=${SELECTED_TAG} \
		-t quay.io/riotkit/wp-auto-update:${VERSION}-${SELECTED_TAG}

push: ## Push image
	${SUDO} docker push quay.io/riotkit/wp-auto-update:${VERSION}-${SELECTED_TAG}

run: ## Run a image
	@echo " >> Wordpress will be running at http://localhost:8000"
	${SUDO} docker run --rm -d --name test_wordpress -p 8000:80 quay.io/riotkit/wp-auto-update:${VERSION}-${SELECTED_TAG}

ci@all: _download_libs ## Build all recent Wordpress versions and push to the registry
	BUILD_PARAMS="--dont-rebuild "; \
	RELEASE_TAG_TEMPLATE="%MATCH_0%"; \
	if [[ "$$COMMIT_MESSAGE" == *"@force-rebuild"* ]] || [[ "${GIT_TAG}" != "" ]]; then \
		BUILD_PARAMS=" "; \
		if [[ "${GIT_TAG}" != "" ]]; then \
			RELEASE_TAG_TEMPLATE="%MATCH_0%-b${GIT_TAG}"; \
		fi; \
	fi; \
	set -x; \
	${CI_UTILS_BIN}/for-each-github-release --exec "make build push VERSION=%MATCH_0% TAG=$$GIT_TAG" --repo-name WordPress/WordPress --dest-docker-repo quay.io/riotkit/wp-auto-update $${BUILD_PARAMS}--allowed-tags-regexp="([0-9\.]+)$$" --release-tag-template="$${RELEASE_TAG_TEMPLATE}" --max-versions=3 --verbose

_download_libs:
	@export RIOTKIT_UTILS_VERSION=${RIOTKIT_UTILS_VERSION} \
	&& export CONFIGURE_PROFILE=False \
	&& export FORCE_INSTALL=False \
	&& export INSTALL_DIR=./.helpers \
	&& curl "https://raw.githubusercontent.com/riotkit-org/ci-utils/v${RIOTKIT_UTILS_VERSION}/ci-integration/any.sh" -s 2>/dev/null | bash
