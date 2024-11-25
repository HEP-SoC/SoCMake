cmake_minimum_required(VERSION 3.25)
project(example NONE)

include("../../../SoCMakeConfig.cmake")

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} VERILOG
    ${PROJECT_SOURCE_DIR}/tb.v
    )

add_subdirectory(adder)

ip_link(${IP} adder)

modelsim(${IP} TARGET_PER_IP)

help()
