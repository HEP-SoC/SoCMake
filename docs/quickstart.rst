Quickstart
----------


SoCMake repository resides on Github: `SoCMake <https://github.com/Risto97/SoCMake>`_.

Installation
============

No installation is needed for using the SoCMake, but instead it is recommended to add the repository as a dependency using `CPM <https://github.com/cpm-cmake/CPM.cmake>`_ package manager.

As a recommendation, you can create ``deps/CPM.cmake`` file in the root of your repository with the following content `CPM.cmake <https://github.com/Risto97/riscv_timer/blob/master/deps/CPM.cmake>`_.
The small CPM.cmake script will download the CPM once at the CMake configuration time.

Then create another file `deps/deps.cmake` where you define your dependencies, for example:

.. code-block:: cmake

    set(CPM_DOWNLOAD_VERSION 0.38.1)             # Define CPM version to be downloaded
    include(${CMAKE_CURRENT_LIST_DIR}/CPM.cmake) # Include the CPM.cmake downloader

    CPMAddPackage(              # Add SoCMake as a package
        NAME SoCMake
        GIT_TAG master          # You can define GIT_TAG or VERSION for versioning
        GIT_REPOSITORY "https://github.com/Risto97/SoCMake.git"  # GIT_REPOSITORY or URL
        )

To see all the possible options for ``CPMAddPackage`` visit ``CPM`` documentation.

Finally we need to include our dependencies in our top ``CMakeLists.txt`` file. Here is a short example:

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.25)
   project(example NONE)

   include("deps/deps.cmake")

As out of source builds are prefered in CMake we should create a build directory.
Your directory tree should look like this:

::

    ├── CMakeLists.txt
    ├── build
    └── deps
        ├── CPM.cmake
        └── deps.cmake

In order to fetch the dependencies we should execute following commands:

.. code-block:: bash

   cd build
   cmake ../

As we can see in the output of the CMake command, we have succesfully downloaded our dependencies.

::

    -- Downloading CPM.cmake to /mnt/ext/work/socmake_example/start/build/cmake/CPM_0.38.1.cmake
    -- CPM: Adding package SoCMake@ (master)
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /mnt/ext/work/socmake_example/start/build

By default the packages will be downloaded in ``${CMAKE_BINARY_DIR}/_deps``, but this can be changed by setting ``FETCHCONTENT_BASE_DIR`` before the first ``CPMAddPackage`` command.



Running a simulation
====================

So far we have just pulled the dependencies, but we didnt create anything meaningful yet.
Lets try to run a simple verilog simulation with `Icarus verilog <https://github.com/steveicarus/iverilog>`_ and or `Verilator <https://github.com/verilator/verilator>`_.

For this step make sure you have Iverilog and/or Verilator installed on your system.

Lets create a simple verilog testbench file:

.. code-block:: verilog

   module tb;
    initial begin
        $display("Simulated with Iverilog, from SoCMake build system\n");
        $finish();
    end
    endmodule

We need to also create a new RTL library and create iverilog/verilator target in CMake.
In case you dont have one of the tools installed, just commend out the function call.

The full CMake file would look like this:

.. code-block:: cmake

    cmake_minimum_required(VERSION 3.25)
    project(example NONE)

    include("deps/deps.cmake")

    add_library(tb INTERFACE        # We define RTL libraries as CMake INTERFACE libraries
        ${PROJECT_SOURCE_DIR}/tb.v  # give the path to our verilog file
        )

    iverilog(tb)                    # Create iverilog target

    enable_language(CXX C)      # We need to enable CXX and C for Verilator, we can also do it in project()
    verilate(verilator_tb       # Name of the executable, will create if it doesnt exist
            tb                  # Name of RTL library
            VERILATOR_ARGS --main)  # Pass --main argument for Verilog only testbenches

Now we can run ``cmake ../`` again inside the build directory.
If we run ``make help`` we can see a list of all the available targets.
In this case we are interested in ``make tb_iverilog`` and ``make verilator_tb``, to compile and run the testbench.

After running ``make tb_iverilog`` or ``make verilator_tb``, we will have respective executables compiled in the build directory, which we can simply run ``./verilator_tb``.
