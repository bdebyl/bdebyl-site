# Description
This repository houses the posts for my site [bdebyl.net](https://bdebyl.net).

I make occasional updates to add blog posts, tutorials, projects write-ups,
etc. The binary static content is all hosted on S3 (i.e. `.jpeg`, `.png`, etc.).

It was setup using **Terraform**, or more
specifically
[alimac/terraform-s3 (from commit 4b32c8d)](https://github.com/alimac/terraform-s3/tree/4b32c8d336ffacc4318c065f8d135973210f535c) --
big thank you to @alimac on GitHub for that!


# Usage
The Makefile is a simple wrapper for `hugo` and `aws s3`, but provides useful
short commands to test the hugo site locally and deploy it to AWS.

## Development
Simply start the Hugo server:
```
make run
```

## Deployment
To deploy to AWS:
```
make deploy
```

## Cache Busting
Bust the Cloudfront cache:
```
make cache
```
