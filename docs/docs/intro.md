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

**SoCMake** is a hardware build system built on top of CMake, designed to automate hardware and SoC design workflows including RTL simulation, code generation, FPGA implementation, and synthesis.

Rather than creating a new build system from scratch, SoCMake extends the mature and widely-used CMake ecosystem to meet the specific needs of hardware design.


Key Features
============

*   **Native Support for `C++` testbenches:** <br />
      - Ideal for C++ and SystemC testbenches, while also supporting Verilog, SystemVerilog, VHDL, or mixed-language testbenches.
*   **Cross compilation of target CPU application code:** <br />
      - Seamlessly compile target CPU applications for SoC designs, leveraging CMake's cross-compilation capabilities.
*  **Familiar CMake Workflow** <br />
      - Benefits from CMake's stability, extensive documentation, and familiar build process that most Linux users already know.
*   **IP block package management** <br />
      - Package IP blocks into self-contained repositories and manage dependencies using the [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) package manager.


Getting started
=============================

Jump to [Getting started](../docs/getting_started) page to learn how to set-up `SoCMake` in your project.

Supported Languages and Tools
=============================

`SoCMake` supports all of the major RTL simulators and number of other EDA tools.

It is very simple to add support for new EDA tools through the SoCMake's `IP` block API and CMake's custom targets.

| Type                  | Supported                    |
|-----------------------|------------------------------|
| **Languages**       | C, C++, SystemC, ASM, Verilog, SystemVerilog, VHDL, SystemRDL, IPXact |
| **RTL Simulation**  | Verilator, IcarusVerilog, GHDL, Xcelium, VCS, Questasim, Vivado Simulator, cocotb |
| **RTL Linting**     | Verible, vhdl_linter |
| **RTL conversion**  | SV2V, tmrg, tmrv |
| **Synthesis**       | Yosys, Vivado |
| **PeakRDL**         | regblock, halcpp, html, docusaurus, ipblocksvg, socgen, ldsgen |


