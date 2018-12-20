# This Makefile was originally taken from https://github.com/alimac/alimac.io/
# Website hostname, used to set:
# - image and container names
# - path to web root (in /tmp directory)
WEBSITE=bdebyl.net

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell aws cloudfront list-distributions \
	--query 'DistributionList.Items[].{id:Id,a:Aliases.Items}[?contains(a,`$(WEBSITE)`)].id' \
	--output text)

default: run

build:
	hugo

run:
	hugo server

clean:
	@# Clean up existing generated site
	rm -rf public/

deploy: clean build
	@# Upload files to S3
	aws s3 sync --acl "public-read" --sse "AES256" public/ s3://$(WEBSITE)

cache:
	@# Invalidate caches
	aws cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths '/*'

.PHONY: build run deploy
