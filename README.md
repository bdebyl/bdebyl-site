# Description

[![Build
Status](https://ci.bdebyl.net/api/badges/bdebyl/bdebyl-site/status.svg)](https://ci.bdebyl.net/bdebyl/bdebyl-site)

This repository houses the posts for my site [bdebyl.net](https://bdebyl.net).
It utilizes the [Hugo](gohugo.io) static-site generator to convert Markdown
files to a static, HTML site. This is then served via AWS S3 behind AWS
Cloudfront (cache).

I make occasional updates to add blog posts, tutorials, projects write-ups,
etc. The binary static content is all hosted on S3 (i.e. `.jpeg`, `.png`, etc.).

## Theme

The theme that this site utilizes is my minimal fork of the
[Hugo Even Theme](https://github.com/bdebyl/hugo-theme-even). The fork strips
out **all** JavaScript which, personally, I've found completely unnecessary for
the purposes of my personal site. Additionally, some custom shortcodes and CSS
changes were added (along with a Makefile for utilizing SCSS).

## Deployment

Deployments are done using my personal [Drone CI
Server](https://ci.bdebyl.net). Each commit has an attached build run to it,
and can be viewed publicly, though the rest is locked down to allow only me
(_sorry_).
