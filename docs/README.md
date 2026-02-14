# Website

This website is built using [Docusaurus 2](https://docusaurus.io/), a modern static website generator. The documentation is hosted at this [link](https://hep-soc.github.io/SoCMake/). The documentation is built and deployed by the CI. It can also be build locally using CMake (see below instructions).

### Local development

To develop in local, you might need to have :
 - sphinx (can be installed with `pip install sphinx-build`)
 - npm (check in a shell if you have it, if not, it should suggest to install it automatically)
 - Node.js with a version greater than 18.0.0, [help to upgrade node version with nvm](https://davidwalsh.name/nvm) (easier with nvm than npm)

From within the docs folder (same level as this README):

```
$ mkdir build && cd build
$ cmake ../
$ make docusaurus_start
```

This should open the website documentation on your localhost.
