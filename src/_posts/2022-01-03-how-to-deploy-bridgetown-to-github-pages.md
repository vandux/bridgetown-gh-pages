---
layout: post
title:  "How to deploy Bridgetown to Github Pages"
date:   2022-01-03 20:37:34 -0500
categories: web-development
---

Github is a great place to host your static website. Unfortunately Bridgetown does not have good documentation for settting this up. The `https://github.com/andrewmcodes/bridgetown-gh-pages-action` has issues.

First you will need to create a branch for github pages `gh-pages`, push it to origin.

Configure Github Actions workflow by creating a file at `.github/workflows/deploy.yml` and populating it with this template:

```yml
name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build:
    name: Deploy to GitHub Pages
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
      - name: Setup Node
        uses: actions/setup-node@v1
        with:
          node-version: "16.x"
      - name: Setup Ruby
        uses: ruby/setup-ruby@master
        with:
          ruby-version: "2.7.1"
      - name: Install Dependencies
        run: |
          bundle config path vendor/bundle
          bundle install
          yarn install
      - name: Build site for deployment
        run: yarn deploy --base_path="/<project-name>" # your repository name
      - name: Deploy to GitHub Pages
        if: success()
        uses: crazy-max/ghaction-github-pages@v2
        with:
          target_branch: gh-pages # target branch
          build_dir: output
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This will install node and ruby, install dependencies, build the site, and push the compiled slug to the target branch `gh-pages`.

Notice the `base_path` option being passed to `yarn deploy`. This is neccessary because Github Pages serves your website on a path. Without this option the paths to dependencies will be wrong causing assets to 404.

Similarly, links will not have include the subpath. So you'll want to create a plugin to apply to paths.

```ruby
# /plugins/filters.rb

class Filters < SiteBuilder
  def build
    liquid_filter "link_path" do |url|
      "#{config.base_path}#{url}"
    end
  end
end
```

```liquid
# /src/_components/navbar.liquid

<nav>
  <a href={{ "/" | link_path }}>Home</a>
  <a href={{ "/about" | link_path }}>About</a>
  <a href={{ "/posts" | link_path }}>Posts</a>
</nav>
```

Github will always attempt to build your project with Jekyll. In order to avoid this you'll have to:
* add `.nojekyll` file to the project root
* add `.nojekyll` file to the root of the `src` directory

Now you will want to push these changes to `main` and then configure github settings pages to use `gh-pages` branch as source.

Github pages serves content on a subpath. This results in 404s for assets.
