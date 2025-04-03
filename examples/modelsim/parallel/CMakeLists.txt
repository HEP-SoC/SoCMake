cmake_minimum_required(VERSION 3.25)
project(parallel_example NONE)

include("../../../SoCMakeConfig.cmake")

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} VERILOG
    ${PROJECT_SOURCE_DIR}/tb.v
    )

add_subdirectory(printer)

foreach(cnt RANGE 0 32)
    stupid_printer(${cnt})
    ip_link(${IP} vendor::lib_${cnt}::printer_${cnt}::0.0.1)
endforeach()

modelsim(${IP} TARGET_PER_IP)

help()
