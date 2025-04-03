cmake_minimum_required(VERSION 3.25)
project(simple_sc_sv_example C CXX)

# Include SoCMake build system
include("../../SoCMakeConfig.cmake")

# Compile SystemC library during initial CMake configure time
systemc_build(VERSION 3.0.0 EXACT_VERSION)

# Add the Verilog DUT
add_subdirectory(adder)

# Create a static library from the DUT with verilator
verilator(adder SYSTEMC
    VERILATOR_ARGS --pins-sc-uint
    )

# Create SystemC main executable
add_executable(simple_sc_sv_example 
    ./sc_main.cpp
    )

# Link SystemC and the static library of the DUT to the executable
target_link_libraries(${PROJECT_NAME} PRIVATE
    # External libraries
    SystemC::systemc

    # Verilated HDL
   adder__vlt 
    )

# Add VERBOSE flag to enable message printing
target_compile_definitions(${PROJECT_NAME} PRIVATE
    VERBOSE
    )

help()

