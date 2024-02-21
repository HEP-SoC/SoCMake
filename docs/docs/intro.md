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

`SoCMake` is a hardware build system based on CMake.
SoCMake can help you automatize yout build process for hardware designs, either running simulation, code generation, FPGA implementation, synthesis etc...

`SoCMake` project does not try to create a new build system, instead it is an extension of `CMake` build system generator.
Since `CMake` is a mature and widely used build system, it can easily cover the requirements needed for hardware design.


Key Features
============

*   **Native Support for `C++` and `C` testbenches:** <br />
    This makes `SoCMake` a natural choice of build system for `C++` and `SystemC` testbenches.
    However it can be also used for `Verilog`, `SV` or `VHDL` only testbenches.
*   **Cross compilation of target CPU application code:** <br />
    CMake's support for cross-compilation makes `SoCMake` a natural choice for System on Chips design, where a test application needs to be cross compiled for the target CPU.
*   **CMake maturity and familiar flow:**
    Since CMake is used as a base build system, `SoCMake` benefits from the stability and the documentation of the project. Configuring the project and running Make targets is also familiar to most `Linux` users.
*   **IP block packaging and management:**
    `SoCMake` provides a way to package IP blocks into independent and self contained `git` repositories. Which can later be fetched with [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) package manager.


Supported Languages and Tools
=============================

Currently `SoCMake` supports a number of EDA tools that were used within the SoC project the tool was originaly deveoped for.
The list is always growing and soon many more tools will be added.

| Type                  | Supported                    |
|-----------------------|------------------------------|
| **Languages**       | C, C++, ASM, Verilog, SystemVerilog, VHDL, SystemRDL |
| **RTL Simulation**  | Verilator, Icarus, GHDL, Xcelium, VCS |
| **RTL Linting**     | Verible |
| **RTL conversion**  | SV2V, tmrg, tmrv |
| **Synthesis**       | Yosys, Vivado |
| **PeakRDL**         | regblock, halcpp, html, docusaurus, ipblocksvg, socgen, ldsgen |
