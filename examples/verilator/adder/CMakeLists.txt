cmake_minimum_required(VERSION 3.27)
project(adder NONE)

add_ip(adder
    DESCRIPTION "Just a simple adder"
    )

ip_sources(${IP} VERILOG
    adder.v
    )
