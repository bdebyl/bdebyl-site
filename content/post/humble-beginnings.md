---
title: "Humble Beginnings"
date: 2017-12-21T01:42:57-05:00
categories: ["Blog"]
tags: ["code"]
thumbnailImagePosition: top
thumbnailImage: "/img/humble-beginnings/main.png"
---
After much deliberation I've finally decided to go with the [**Tranquilpeak**](https://github.com/kakawait/hugo-tranquilpeak-theme) theme. However, before this I ran into a slew of issues with the badly ported [**Tracks**](https://github.com/ageekymonk/hugo-tracks-theme) theme from WordPress
<!--more-->

If you want a general overview, feel free to check out the relevant [commit](https://github.com/bdebyl/hugo-tracks-theme/commit/86ca4963c4d0a67ddb1560197c91617e7d3e3754) on my GitHub fork.

<!-- toc -->

# Rough Start
The first thing I noticed was that the navigation bar seemed a bit off.


{{< image classes="center" src="/img/humble-beginnings/header-problem.png" title="Navbar Issue" >}}

The links show as numbers and attempt to link to `/0`, `/1`, and `/2` which lead to 404s. This didn't  seem like the intended functionality. It turned out to be a problem with the usage of the following variable: `.Site.Sections`

As I'm still learning the ins and outs of Hugo, I'm not familiar with what a section *should* be, but I did know the `sidebar.html` layout file didn't seem to do anything nor exist anywhere on the site (even on mobile screen sizes). I did attempt to find out how sections work by experiment with directories along with `index.md` /  `_index.md` files within the `content/` folder. Though, I was unsuccessful in getting the structure I wanted to appear, appear, along with not really understanding why `0` and `0` pages even existed.

# The Fix
The issue lied in the following chunk of code for `layouts/partials/headers.html`:
```html
<div class="col-md-6">
  <div class="menu">
    <a href="/">Home /</a>
    {{ range $name, $taxonomy := .Site.Sections }}
    {{ if ne $name "post" }}
    <a href="/{{ $name | urlize }}">{{ $name }} / </a>
    {{ end }}
    {{ end }}
  </div>
```

For some reason it seemed that `.Site.Sections` would populate as `0` and `1`. Now, this may be an error of my part from lack of understanding of how Hugo works, but I have yet to make sense of the documentation as far as sections go.


In any case, I borrowed the code found in `layouts/partials/sidebar.html` to include the nav links I desired:
```html
<div class="col-md-6">
  <div class="menu">
    {{ $url := .Site.BaseURL }}
    {{ range .Site.Params.navlinks }}
    <a href="{{ $url }}{{ .url }}">{{ .name }} /</a>
    {{ end }}
  </div>
```

----

# But Wait, There's More!
After getting more comfortable with how themes are designed for Hugo, I found a slew of other problems with the ported **Tracks** theme:

* Improper HTML for `/about/` and `/contact/` resulting in a sloppy looking, inconsistent site.
* Redundant `portfolio.html`: duplicated HTML code already used in `category.html`
* Completely unused:
  * `layouts/_default/taxonomy.html`
  * `layouts/_default/list.html`
  * `<div class="col-md-10 category-description">` in `layouts/partials/category.html`
* Missing:
  * Pagination
  * Syntax Highlighting

At the this point in time I decided it was no longer worth my time in trying to re-work something I wasn't very familiar with, as my main objective was simply to get a portfolio website with blog functionality up and running.
