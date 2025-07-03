cmake_minimum_required(VERSION 3.25)
project(simple_verilog_example NONE)

include("../../../../SoCMakeConfig.cmake")

add_ip(tb
    DESCRIPTION "Simple verilog testbench")

ip_sources(${IP} VERILOG
    tb.v)

find_package(vendor__ip__mult CONFIG REQUIRED
    HINTS ${PROJECT_SOURCE_DIR}/../build/here/vendor/ip/mult/0.0.1
    )
# add_subdirectory("..//" mult)
ip_link(${IP} vendor::ip::mult::0.0.1)


iverilog(${IP})
ip_install(${IP})

help()
