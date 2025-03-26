cmake_minimum_required(VERSION 3.25)
project(simple_verilog_example NONE)

include("../../../../SoCMakeConfig.cmake")

add_ip(tb
    DESCRIPTION "Simple verilog testbench")

ip_sources(${IP} VERILOG
    tb.v)

find_package(adder CONFIG REQUIRED
    HINTS ../install
    )
ip_link(${IP} adder)

modelsim(${IP})

help()
