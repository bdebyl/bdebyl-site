# Description

This repository houses the posts for my site [bdebyl.net](https://bdebyl.net).

I make occasional updates to add blog posts, tutorials, projects write-ups,
etc. The binary static content is all hosted on S3 (i.e. `.jpeg`, `.png`, etc.).

It was setup using **Terraform**, or more
specifically
[alimac/terraform-s3 (from commit 4b32c8d)](https://github.com/alimac/terraform-s3/tree/4b32c8d336ffacc4318c065f8d135973210f535c) --
big thank you to [**@alimac**](https://github.com/alimac/) on GitHub for that!

# Usage

The Makefile is a simple wrapper for the `bdebyl/hugo` Docker image and `aws
s3`, but provides useful short commands to test the hugo site locally and deploy
it to AWS.

## Dependencies

[Docker](https://docs.docker.com/install/) is required to run the make targets
for hosting and generating the static Hugo site.

## Development

To build the static content _without_ running the Hugo server:

```bash
make build
```

To start the Hugo server on `http://localhost:1313`:

```bash
make run
```

## Deployment

To deploy to AWS:

```bash
make deploy
```

## Cache Busting

Bust the Cloudfront cache:

```bash
make cache
```
