---
title: "Humble Beginnings"
date: 2017-12-21
lastmod: 2019-01-16
categories: ["Blog"]
tags: ["code"]
---
After running into too many road blocks I've decided to go with
the [**Tranquilpeak**](https://github.com/kakawait/hugo-tranquilpeak-theme)
theme for this site. Before this, I was really looking forward to using
the [**Tracks**](https://github.com/ageekymonk/hugo-tracks-theme) theme (ported
from WordPress)

<!--more-->
# Disclaimer

{{< admonition warning "Out of Date" >}}
The information in this article is **out-of-date**. I am, and have been, using my
own fork of the [hugo-even-theme](https://gitlab.com/bdebyl/hugo-theme-even) on
my [GitLab](https://gitlab.com/bdebyl) profile.
{{< /admonition >}}

---

If you want a general overview, feel free to check out the
relevant
[commit](https://github.com/bdebyl/hugo-tracks-theme/commit/86ca4963c4d0a67ddb1560197c91617e7d3e3754) on
my GitHub fork of the **Tracks** theme.

# Rough Start

Right off the bat I noticed the navigation bar seemed a bit off, to say the least:

<center>![Problem Navbar](/static/img/humble-beginnings/header-problem.png)</center>

The links showed as numbers and pointed to `/0`, `/1`, and `/2`
respectively. These, of course, lead to 404s. It didn't seem like the intended
behavior, so I kept digging. Eventually, I found out the problem lied in the
usage of the `.Site.Sections` variable used in a loop to populare items in the
page header.

> **.Site.Sections**
>
> top-level directories of the site.

\- [Source](https://gohugo.io/variables/site/#site-variables-list)

As I'm still learning the ins and outs of Hugo, I'm not familiar enough with
what a section *should* be beyond what the documentation states. I did attempt
to find out how sections work by experimenting with directories in `content/`
and files such as `index.md` / `_index.md`. Regretfully, I was unsuccessful in
figuring out the proper structure to utilize `.Site.Sections`. I still do not
fully understanding where the `0` and `1` "sections" even originated from. In
any case, I decided the only course of action was to use something other than
sections for the behavior I wanted.

# The Fix

Looking at other template files in the theme's layout, I stumbled on a chunk of
code in `layouts/partials/headers.html` that defined the behavior of the
aforementioned "navbar" problem:

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

The original uses the `.Site.Sections` variable, which I replaced with
`.Site.Params.navlinks`. **This** seemed like intended behavior as the
user-defined `config.toml` nav links weren't ever utilized or populated anywhere
on the site.

<center>![Nav Links from Tracks Theme config](/static/img/humble-beginnings/tracks-config.png)</center>

I borrowed the code found in `layouts/partials/sidebar.html` (*which also never
appears to be used*) to include the nav links and get my desired behavior:

```html
<div class="col-md-6">
<div class="menu">
{{ $url := .Site.BaseURL }}
{{ range .Site.Params.navlinks }}
<a href="{{ $url }}{{ .url }}">{{ .name }} /</a>
{{ end }}
</div>
```

# But Wait, There's More

After getting more comfortable with how themes are written for Hugo, I found a
slew of other problems with the ported **Tracks** theme:

* Improper HTML for `/about/` and `/contact/` resulting in a sloppy looking, inconsistent site.
* Redundant `portfolio.html`: duplicated HTML code already used in `category.html`
* Completely unused:
* `layouts/partials/sidebar.html`
* `layouts/_default/taxonomy.html`
* `layouts/_default/list.html`
* `<div class="col-md-10 category-description">` in `layouts/partials/category.html`
* Missing:
* Pagination
* Syntax Highlighting

At this point I decided it was no longer worth my time in trying to re-work
something I wasn't very familiar with. My main objective was simply to get a
portfolio website with blog functionality up and running, not to custom build or
*re*-build a theme. **Tranquilpeak** offered exactly what I wanted, though not
necessarily *how* I wanted them. You can't always get what you want :)
