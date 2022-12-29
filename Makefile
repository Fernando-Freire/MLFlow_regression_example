################################################################################
##                                   COMMANDS                                 ##
################################################################################

MAKE += --no-print-directory RECURSIVE=1

ifndef VERBOSE
COMPOSE := docker-compose 2>/dev/null
COMPOSE_BUILD := $(COMPOSE) build -q
else
COMPOSE := docker-compose
COMPOSE_BUILD := $(COMPOSE) build
endif

################################################################################
##                                   COLORS                                   ##
################################################################################

RES := \033[0m
MSG := \033[1;36m
ERR := \033[1;31m
SUC := \033[1;32m
WRN := \033[1;33m
NTE := \033[1;34m

################################################################################
##                                 AUXILIARY                                  ##
################################################################################

# Variable do allow is-empty and not-empty to work with ifdef/ifndef
export T := 1

define is-empty
$(strip $(if $(strip $1),,T))
endef

define not-empty
$(strip $(if $(strip $1),T))
endef

define message
printf "${MSG}%s${RES}\n" $(strip $1)
endef

define success
(printf "${SUC}%s${RES}\n" $(strip $1); exit 0)
endef

define warn
(printf "${WRN}%s${RES}\n" $(strip $1); exit 0)
endef

define failure
(printf "${ERR}%s${RES}\n" $(strip $1); exit 1)
endef

define note
(printf "${NTE}%s${RES}\n" $(strip $1); exit 0)
endef

################################################################################
##                                   AWS                                      ##
################################################################################

SHELL := /bin/bash

# Do not execute in recursive calls or within Jenkins
ifdef $(call is-empty,${RECURSIVE})
export AWS_ACCESS_KEY_ID := $(shell aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY := $(shell aws configure get aws_secret_access_key)
export AWS_SESSION_TOKEN := $(shell aws configure get aws_session_token)
endif

################################################################################
##                                DOCKER BUILD                                ##
################################################################################

build-jupyter:
	@$(call message,"Construindo imagem docker para notebooks")
	@$(COMPOSE_BUILD) jupyter

build-dev:
	@$(call message,"Construindo imagem docker para desenvolvimento")
	@$(COMPOSE_BUILD) dev

build-prod:
	@$(call message,"Construindo imagem docker para produção")
	@$(COMPOSE_BUILD) prod

build:
	@$(MAKE) build-jupyter
	@$(MAKE) build-dev
	@$(MAKE) build-prod

release-image:
	@$(MAKE) build-prod
	@$(call message,"Releasing version ${TAG} ")
	@docker image tag ${EXAMPLE_IMAGE}:${EXAMPLE_TAG} ${EXAMPLE_IMAGE}:${TAG}
	@docker push ${EXAMPLE_IMAGE}:${TAG}
	
bump-and-release:
	@$(call message,"Bumping ${KIND} of example version")
	@(poetry version ${KIND})
	@$(MAKE) release-image TAG=${POETRY_VERSION}
	@git add pyproject.toml
	@git commit -m "Release version: v${POETRY_VERSION}"
	@git tag v${POETRY_VERSION}-ETL
	@git push origin HEAD --tags


################################################################################
##                               LINT & FORMAT                                ##
################################################################################

isort:
	@$(call message,"Running isort")
	@$(COMPOSE) run -T --rm --entrypoint isort dev steps
	@$(COMPOSE) run -T --rm --entrypoint isort dev tests

black:
	@$(call message,"Running black")
	@$(COMPOSE) run -T --rm --entrypoint black dev steps
	@$(COMPOSE) run -T --rm --entrypoint black dev tests

autoflake:
	@$(call message,"Running autoflake")
	@$(COMPOSE) run --rm --entrypoint autoflake dev \
		--in-place --remove-all-unused-imports --remove-unused-variables \
		--ignore-init-module-imports --expand-star-imports --recursive \
		steps

	@$(COMPOSE) run --rm --entrypoint autoflake dev \
		--in-place --remove-all-unused-imports --remove-unused-variables \
		--ignore-init-module-imports --expand-star-imports --recursive \
		tests

flake8:
	@$(call message,"Running flake8")
	@$(COMPOSE) run -T --rm --entrypoint flake8 dev steps
	@$(COMPOSE) run -T --rm --entrypoint flake8 dev tests

lint:
	@$(MAKE) flake8

format:
	@$(MAKE) black
	@$(MAKE) isort
	@$(MAKE) autoflake


################################################################################
##                                 TESTS                                      ##
################################################################################

test-env:
	@$(COMPOSE) up -d db minio mc web 

clear-test-env:
	@$(COMPOSE) down 

step-tests:
	@$(COMPOSE) run --rm --entrypoint pytest dev -v tests/


run-ingest-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes run --step ingest --profile local'" prod -v 

run-transform-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes run --step transform --profile local'" prod -v 

run-split-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes run --step split --profile local'" prod -v 

run-train-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes run --step train --profile local'" prod -v 

run-custom-metrics-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes run --step custom_metrics --profile local'" prod -v 

inspect-ingest-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes inspect --step ingest --profile local'" prod -v 

inspect-transform-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes inspect --step transform --profile local'" prod -v 

inspect-split-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes inspect --step split --profile local'" prod -v 

inspect-train-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes inspect --step train --profile local'" prod -v 

inspect-custom-metrics-step:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes inspect --step custom_metrics --profile local'" prod -v 


check-ingest-step:
	@$(MAKE) run-ingest-step
	@$(MAKE) inspect-ingest-step

check-transform-step:
	@$(MAKE) run-transform-step
	@$(MAKE) inspect-transform-step

check-split-step:
	@$(MAKE) run-split-step
	@$(MAKE) inspect-split-step

check-train-step:
	@$(MAKE) run-train-step
	@$(MAKE) inspect-train-step

check-custom-metrics-step:
	@$(MAKE) run-custom-metrics-step
	@$(MAKE) inspect-custom-metrics-step

clear-steps-recipes:
	@$(COMPOSE) run --rm --entrypoint "sh -c 'mlflow recipes clean --profile=local'" prod -v 


all-tests:
	@$(MAKE) build
	@$(MAKE) test-env
	@$(MAKE) step-tests
	@$(MAKE) clear-steps-recipes
	@$(MAKE) check-ingest-step
	@$(MAKE) check-transform-step
	@$(MAKE) check-split-step
	@$(MAKE) check-train-step
	@$(MAKE) check-custom-metrics-step
	@$(MAKE) clear-steps-recipes
	@$(MAKE) clear-test-env
	@$(call success,"Flawless test execution, congratulations")