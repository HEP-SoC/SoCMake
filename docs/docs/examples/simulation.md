---
sidebar_position: 1
---

# Simulation


In the previous section [Getting Started](../getting_started.mdx), we saw how to download SoCMake inside our project.

Let's try to run a simple Verilog testbench now with [Icarus Verilog](https://github.com/steveicarus/iverilog) and/or [Verilator](https://github.com/verilator/verilator).

For this step make sure you have Iverilog and/or Verilator installed on your system.

Lets create a simple verilog testbench file:

import CodeBlock from '@theme/CodeBlock';
const tb_v = require('!!raw-loader!../../../examples/sim_example/tb.v')?.default;
const cmakelists = require('!!raw-loader!../../../examples/sim_example/CMakeLists.txt')?.default;

## tb.v 

The following testbench will just print something to the stdout.

<CodeBlock language="verilog" title="tb.v" showLineNumbers>{tb_v}</CodeBlock>


## CMakeLists.txt

The following `CMakeLists.txt` will create a library, add sources and create verilator and iverilog Makefile targets.

<CodeBlock language="cmake" title="CMakeLists.txt" showLineNumbers>{cmakelists}</CodeBlock>

### add_ip()

We are creating an `IP` library called `tb` using `add_ip()` function.
Function add_ip takes the following arguments:
*   First argument is positional ** NAME ** of the defined library
*   ** VENDOR ** - name of the vendor (your company, organization, ...)
*   ** LIBRARY ** - name of the library which the IP is part of
*   ** VERSION ** - Version number of the IP

The library that will be created will hold a name **{VENDOR}**\_\_**{LIBRARY}**\_\_**{NAME}**\_\_**{VERSION}**, there will be also a CMake [alias library](https://cmake.org/cmake/help/latest/command/add_library.html#alias-libraries) that is created with the name **{VENDOR}**::**{LIBRARY}**::**{NAME}**::**{VERSION}**.

In this a library called **cern::ip::tb::0.0.1** is created.<br/>
This function also sets `IP` variable in the current scope from where it was called. The IP will hold the non alias full library name.


### ip_sources()

To add design sources to the `IP` library, we can use `ip_sources()` function.
The function takes
*   First argument is positional ** NAME ** of the library to add sources to.
*   Second argument is positional ** TYPE ** and represents the file type to be added. 
*   Third argument is positional ** SOURCES ** and is a list of source files to be added

:::info
Using just the name of the library `tb` is possible only if the add_ip() call is in the same CMakeLists.txt (subdirectory), and it was the last library added.
In other cases you can use:
*   `${IP}` same as `tb`, should be in same subdirectory and last library added
*   Full name `cern__ip__tb__0.0.1` (always works, from any subdirectory)
*   Alias libray name `cern::ip::tb::0.0.1` (always works, from any subdirectory)

:::

### iverilog()

This function will add a target to compile the Icarus Verilog testbench.
The name of the created `Makefile` target will be: `${IP}_iverilog` in this case : `cern__ip__tb__0.0.1_iverilog`.

### verilator()

This function will add a target to compile the Verilator testbench.
In this case because it is a Verilog only testbench, we are passing `MAIN` argument, to let Verilator create a `main.cpp` file for us.<br/>
For a custom C++ testbench checkout the next example.

The name of the created `Makefile` target will be: `${IP}_verilate` in this case : `cern__ip__tb__0.0.1_verilate`.


## Running the example 


### Video example

Checkout the video example below to see how to run the simulation.

<details>
  <summary><strong>Video demonstration</strong></summary>

import ReactPlayer from 'react-player'

<ReactPlayer width="100%" height="100%" controls url='/examples/sim_example.mp4' />

</details>

### Instructions

To run the example we need to create a build directory as always:

```bash
mkdir build
cd build
```

Then we generate Makefiles with:

```bash
cmake ../
```

Now we have `Makefile` in the build directory, which contain generated targets.
The targets we are interested in are:
*   `cern__ip__tb__0.0.1_iverilog`
*   `cern__ip__tb__0.0.1_verilate`

To run the simulation we can do:

```bash
make cern__ip__tb__0.0.1_iverilog              # Compile with Icarus Verilog`
make cern__ip__tb__0.0.1_verilate -j$(nproc)   # Compile with Verilator`
```

We can compile Verilator testbench with maximum threads with `-j$(nproc)` flag.

Once we execute one or both of these targets we will have the testbenches compiled as executables and available to run as a normal executables.
The executables will be present in `${PROJECT_BINARY_DIR}` in this case `build` directory.
*   `cern__ip__tb__0.0.1_iv`
*   `cern__ip__tb__0.0.1_verilator_tb`

