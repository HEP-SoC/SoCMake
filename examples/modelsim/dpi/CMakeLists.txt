cmake_minimum_required(VERSION 3.25)
project(dpi_example NONE)

include("../../../SoCMakeConfig.cmake")

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} SYSTEMVERILOG
    ${PROJECT_SOURCE_DIR}/tb.sv
    )

add_subdirectory(hello)

ip_link(${IP} hello_dpi)

modelsim(${IP})

help()
