---
sidebar_position: 1
---

# Introduction

<div style={{textAlign: 'center'}}><img
    src={require('../static/img/SoCMakeLogo.png').default}
    width="70%"
    className="center"
/>
</div>

`SoCMake` is a build system for Hardware and SoC designers. It aims to provide a complete workflow for simulating, implementing and developing System on Chip designs.

`SoCMake` is not a new build system, instead it is an extension of `CMake` build system generator.
`CMake` is a mature and widely used build system, and it can easily cover the requirements needed for hardware design.

The decision behind developing `SoCMake` instead of using something like [FuseSoC](https://github.com/olofk/fusesoc) or [hdlmake](https://hdlmake.readthedocs.io/en/master/#) is the need for a good `C++` support.
Having a native C++ support, gives ability to easily compile C++ testbenches and also C or C++ application codes for simulated processors.
This makes SoCMake especially good for SoC designs and eliminates the need for yet another build system for simulation and software stack.

SoCMake provides additional CMake functions to define Hardware IP blocks, link them together to describe dependencies, run EDA tools on the IP blocks and finally package them so they are easily reusable.

Fetching newly created IP blocks and package managment can be done using [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)
