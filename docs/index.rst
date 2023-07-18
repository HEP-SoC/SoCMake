.. image:: source/graphics/SoCMakeLogo5.png
  :width: 50%
  :alt: Alternative text
  :align: center

SoCMake
=======

``SoCMake`` is a build system for RTL and SoC designers.
It aims to provide a complete workflow for simulating, implementing, developing of System on Chip designs.

Instead of developing a new build system, ``SoCMake`` relies on CMake.
The rationale behind using CMake is to use the same build system for SoC applications, verification environment and implementation.

Therefore the big difference compared to the popular `FuseSoC <https://github.com/olofk/fusesoc>`_ or `hdlmake <https://hdlmake.readthedocs.io/en/master/#>`_ is the C++ support and cross compiling support.
However the project is still in early stages, so the tool support is nowhere near FuseSoC.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   source/quickstart.rst
   source/build_system.rst
   source/cmake_api/index.rst


`Build system <https://risto97.github.io/SoCMake/build_system.html>`_
=====================================================================

SoCMake is relying on `CMake <https://cmake.org/>`_ for the build system, while it provides some additional functions for ``RTL libraries``.

| For more information on how the build system works take a look at `build_system <https://risto97.github.io/SoCMake/build_system.html>`_ secition

`Package Manager <https://risto97.github.io/SoCMake/package_manager.html>`_
===========================================================================

SoCMake provides package management functionality through `CPM.cmake <https://github.com/cpm-cmake/CPM.cmake>`_.
Take a look at how to use it to bootstrap SoCMake `bootstrap <https://risto97.github.io/SoCMake/quickstart.html#installation>`_.

