cmake_minimum_required(VERSION 3.25)
project(adder NONE)

add_ip(cern::ip::adder::0.0.1
    DESCRIPTION "Just a simple adder"
    )

ip_sources(adder VERILOG
    ${PROJECT_SOURCE_DIR}/adder.v
    )
