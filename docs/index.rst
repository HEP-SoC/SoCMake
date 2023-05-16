.. image:: SoCMakeLogo5.png
  :width: 50%
  :alt: Alternative text
  :align: center

SoCMake
=======

``SoCMake`` is a build system for RTL and SoC designers.
It aims to provide a complete workflow for simulating, implementing, developing of System on Chip designs.

Instead of developing a new build system, ``SoCMake`` relies on CMake.
The rationale behind using CMake is to use the same build system for SoC applications, verification environment and implementation.

Therefore the main difference compared to the popular `FuseSoC <https://github.com/olofk/fusesoc>`_ or `hdlmake <https://hdlmake.readthedocs.io/en/master/#>`_ is the C++ support and cross compiling support.
However the project is still in early stages, so the tool support is nowhere near FuseSoC.


.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   quickstart.rst
        

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
