cmake_minimum_required(VERSION 3.27)
project(iverilog_compile_args NONE)

add_ip(iverilog_compile_args
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
    )
ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb.v)

# SV_COMPILE_ARGS are forwarded verbatim to the iverilog command line.
# The testbench checks that -DEXTRA_DEF was received by the preprocessor.
iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb
    SV_COMPILE_ARGS -DEXTRA_DEF
    )

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
