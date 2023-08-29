cmake_minimum_required(VERSION 3.25)
project(example NONE)

include("deps/deps.cmake")

add_ip(tb           # Name of the IP block
    VENDOR cern     # Vendor name (can be ommited, but not recommended)
    LIBRARY ip      # Library name (can be ommited, but not recommended)
    VERSION 0.0.1   # Version Number (can be ommited, but not recommended)
    )

ip_sources(tb VERILOG           # Add source files to the VERILOG file set
    ${PROJECT_SOURCE_DIR}/tb.v
    )

iverilog(tb) # Create iverilog target

verilate(tb  # Create verilate target
    MAIN     # Let Verilator create a main.cpp testbench
    )
