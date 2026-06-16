# Website

This website is built using [Docusaurus 3](https://docusaurus.io/), a modern static website generator. The documentation is hosted at this [link](https://hep-soc.github.io/SoCMake/). The documentation is built and deployed by the CI. It can also be build locally using CMake (see below instructions).

### Local development

To develop in local, you might need to have :
 - npm (check in a shell if you have it, if not, it should suggest to install it automatically)
 - Node.js with a version greater than or equal to 20.0.0 (required by Docusaurus 3.10+), [help to upgrade node version with nvm](https://davidwalsh.name/nvm) (easier with nvm than npm)

From within the docs folder (same level as this README):

```
$ python -m venv .venv
$ source .venv/bin/activate
$ pip install -r python_requirements.txt
$ mkdir build && cd build
$ cmake ../
$ make docusaurus_start
```

This should open the website documentation on your localhost.

### CI deployment and PR previews

Two GitHub Actions workflows handle the docs:

- [`pages.yml`](../.github/workflows/pages.yml) builds and deploys the docs to the `gh-pages` branch (served at the link above) on every push to `master`.
- [`pages_preview.yml`](../.github/workflows/pages_preview.yml) builds a preview for any pull request that touches `docs/` or `cmake/` (the latter feeds the auto-generated API reference), and publishes it to a per-PR sub-path on `gh-pages`: `https://hep-soc.github.io/SoCMake/pr-preview/pr-<number>/`. The preview link is posted as a comment on the PR and the sub-path is removed automatically once the PR is closed.

The preview workflow builds with the `DOCS_BASE_URL` environment variable set to the PR's sub-path, which overrides the `baseUrl` in [`docusaurus.config.js`](docusaurus.config.js) (it defaults to `/SoCMake/` otherwise, e.g. for local builds or the `master` deploy).

Note: PR previews only work for branches pushed within this repository — `GITHUB_TOKEN` is read-only for `pull_request` events triggered from forks, so the deploy step is skipped/fails for external contributions.
