# This Makefile was originally taken from https://github.com/alimac/alimac.io/
# Website hostname, used to set:
# - image and container names
# - path to web root (in /tmp directory)
WEBSITE=bdebyl.net
STATIC_DIR=static

HUGO_IMAGE_NAME=bdebyl/hugo
HUGO_IMAGE_TAG=0.4.1
HUGO_IMAGE=$(HUGO_IMAGE_NAME):$(HUGO_IMAGE_TAG)

AWS_IMAGE_NAME=bdebyl/awscli
AWS_IMAGE_TAG=0.2
AWS_IMAGE=$(AWS_IMAGE_NAME):$(AWS_IMAGE_TAG)

# Container Variables
RUN_USER=--user $(shell id -u $$USER):$(shell id -g $$USER)
RUN_VOL=-v $(shell pwd):/src
AWS_ENV=-e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" -e "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
S3_CMD=s3 sync --acl "public-read" --sse "AES256" public/ s3://${WEBSITE}

DOCKER_PORT=-p 1313:1313/tcp
DOCKER_RUN=docker run --rm ${RUN_USER} ${RUN_VOL}

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell docker run --rm ${AWS_ENV} ${AWS_IMAGE} cloudfront list-distributions \
	--query 'DistributionList.Items[].{id:Id,a:Aliases.Items}[?contains(a,`${WEBSITE}`)].id' \
	--output text)

static:
	s3fs -o use_path_request_style bdebyl.static ${STATIC_DIR}

unmount:
	fusermount -u ${STATIC_DIR}

build:
	$(DOCKER_RUN) ${HUGO_IMAGE}

_run: static
	-$(DOCKER_RUN) ${DOCKER_PORT} ${HUGO_IMAGE} server --bind=0.0.0.0
run: _run unmount

version:
	$(DOCKER_RUN) ${HUGO_IMAGE} version

new:
	$(DOCKER_RUN) ${HUGO_IMAGE} new post/$(shell read -p "Post Name (i.e. my_post.md): " pn; echo $$pn)

thumbnails:
	@./make-thumbs.sh

clean:
	@# Clean up existing generated site
	rm -rf public/ resources/

deploy: clean build
	@# Upload files to S3
	@$(DOCKER_RUN) ${AWS_ENV} ${AWS_IMAGE} ${S3_CMD}

cache:
	@# Invalidate caches
	@cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'

# Default target for make (<=3.80)
.PHONY: static unmount build _run run version new thumbnails clean deploy cache
default: build
