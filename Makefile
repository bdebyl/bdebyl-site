WEBSITE=debyl.io

AWS=aws --profile default

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell ${AWS} cloudfront list-distributions \
	--query 'DistributionList.Items[].{id:Id,a:Aliases.Items}[?contains(a,`${WEBSITE}`)].id' \
	--output text)
S3_SYNC=s3 sync --sse "AES256" public/ s3://${WEBSITE}
CLOUDFRONT_INVALIDATE=cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'

# Default target for make (<=3.80)
default:
	-hugo server
.PHONY: default

build:
	-hugo build
.PHONY: build

clean:
	rm -rfv public/

deploy: clean build
	@# Upload files to S3
	${AWS} ${S3_SYNC}
.PHONY: deploy

cache:
	@# Invalidate caches
	${AWS} ${CLOUDFRONT_INVALIDATE}
.PHONY: cache
