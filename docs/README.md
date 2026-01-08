# Website

This website is built using [Docusaurus 2](https://docusaurus.io/), a modern static website generator. The documentation is hosted at this [link](https://hep-soc.github.io/SoCMake/). The documentation is built and deployed by the CI. It can also be build locally using CMake (see below instructions).

### Local development

From within the docs folder (same level as this README):

```
$ mkdir build && cd build
$ cmake ../
$ make docusaurus_start
```

This should open the website documentation on your localhost.
