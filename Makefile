# This Makefile was originally taken from https://github.com/alimac/alimac.io/
# Website hostname, used to set:
# - image and container names
# - path to web root (in /tmp directory)
WEBSITE=bdebyl.net
STATIC_DIR=static

HUGO_IMAGE_NAME=bdebyl/hugo
HUGO_IMAGE_TAG?=latest
HUGO_IMAGE=$(HUGO_IMAGE_NAME):$(HUGO_IMAGE_TAG)

AWS_IMAGE_NAME=bdebyl/awscli
AWS_IMAGE_TAG?=latest
AWS_IMAGE=$(AWS_IMAGE_NAME):$(AWS_IMAGE_TAG)

# Container Variables
RUN_USER=--user $(shell id -u $$USER):$(shell id -g $$USER)
RUN_VOL=-v $(shell pwd):/src
AWS_ENV=-e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" -e "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"

MOUNT_BUCKET?=1

DOCKER_PORT=-p 1313:1313/tcp
DOCKER_RUN=docker run --rm ${RUN_USER} ${RUN_VOL}

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell docker run --rm ${AWS_ENV} ${AWS_IMAGE} cloudfront list-distributions \
	--query 'DistributionList.Items[].{id:Id,a:Aliases.Items}[?contains(a,`${WEBSITE}`)].id' \
	--output text)
S3_CMD=s3 sync --acl "public-read" --sse "AES256" public/ s3://${WEBSITE}
CLOUDFRONT_CMD=cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'

build:
	$(DOCKER_RUN) ${HUGO_IMAGE}

mount:
	if [ ! -d "${STATIC_DIR}/static" ]; then aws s3 sync s3://bdebyl.static static/; fi

unmount:
	if [ -d "${STATIC_DIR}/static" ]; then rm -rfv static/

run:
	-$(DOCKER_RUN) -it ${DOCKER_PORT} ${HUGO_IMAGE} -D server --bind=0.0.0.0

version:
	$(DOCKER_RUN) ${HUGO_IMAGE} version

new:
	$(DOCKER_RUN) ${HUGO_IMAGE} new post/$(shell read -p "Post Name (i.e. my_post.md): " pn; echo $$pn)

clean:
	@# Clean up existing generated site
	rm -rf public/ resources/

deploy: clean build
	@# Upload files to S3
	@$(DOCKER_RUN) ${AWS_ENV} ${AWS_IMAGE} ${S3_CMD}

cache:
	@# Invalidate caches
	@$(DOCKER_RUN) ${AWS_ENV} ${AWS_IMAGE} ${CLOUDFRONT_CMD}

# Default target for make (<=3.80)
.PHONY: static mount unmount build _run run version new clean deploy cache
default: build
