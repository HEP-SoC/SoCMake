include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)

project(adder NONE)

add_ip(adder
    DESCRIPTION "Just a simple adder")

ip_sources(${IP} VERILOG
    ./adder/adder.v
    # HEADERS
    # ./adder/adder.v
    )

# ip_include_directories(${IP} VERILOG
#     ./adder)

ip_install(${IP})
