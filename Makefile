# This Makefile was originally taken from https://github.com/alimac/alimac.io/
# Website hostname, used to set:
# - image and container names
# - path to web root (in /tmp directory)
WEBSITE=bdebyl.net

DOCKER_IMAGE_NAME=bdebyl/hugo
DOCKER_IMAGE_TAG=0.2
DOCKER_IMAGE=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

# Container Variables
RUN_USER=--user $(shell id -u $$USER):$(shell id -g $$USER)
RUN_VOL=-v $(shell pwd):/src
RUN_PORT=-p 1313:1313/tcp

DOCKER_RUN=docker run -it --rm ${RUN_USER} ${RUN_VOL} ${RUN_PORT} ${DOCKER_IMAGE}

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell aws cloudfront list-distributions \
	--query 'DistributionList.Items[].(id:Id,a:Aliases.Items)[?contains(a,`$(WEBSITE)`)].id' \
	--output text)

build:
	$(DOCKER_RUN)

run:
	$(DOCKER_RUN) server --bind=0.0.0.0

new:
	$(DOCKER_RUN) new post/$(shell read -p "Post Name (i.e. my_post.md): " pn; echo $$pn)

clean:
	@# Clean up existing generated site
	rm -rf public/ resources/

deploy: clean build
	@# Upload files to S3
	aws s3 sync --acl "public-read" --sse "AES256" public/ s3://$(WEBSITE)

cache:
	@# Invalidate caches
	aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'

# Default target for make (<=3.80)
.PHONY: build run deploy
default: run
