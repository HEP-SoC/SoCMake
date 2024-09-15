cmake_minimum_required(VERSION 3.25)
project(example NONE)

include("deps/deps.cmake")

add_ip(cern::ip::tb::0.0.1
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} VERILOG           # Add source files to the VERILOG file set
    ${PROJECT_SOURCE_DIR}/tb.v
    )

iverilog(${IP})

verilate(${IP}  # Create verilate target
    MAIN)        # Let Verilator create a main.cpp testbench
    
help()
