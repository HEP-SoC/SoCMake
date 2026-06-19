cmake_minimum_required(VERSION 3.27)
project(iverilog_outdir NONE)

add_ip(iverilog_outdir
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
    )
ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb.v)

iverilog(${IP} OUTDIR ${PROJECT_BINARY_DIR}/sim_out)

include(CTest)

# Binary must be in the custom OUTDIR, not the default BINARY_DIR
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/sim_out/${IP}_iverilog_tb)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
