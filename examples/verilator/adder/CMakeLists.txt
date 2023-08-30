cmake_minimum_required(VERSION 3.25)
project(adder NONE)

add_ip(adder
    VENDOR cern
    LIBRARY ip
    VERSION 0.0.1
    )

ip_sources(adder VERILOG
    ${PROJECT_SOURCE_DIR}/adder.v
    )
