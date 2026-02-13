cmake_minimum_required(VERSION 3.27)
project(iverilog_multi_top NONE)

add_ip(iverilog_multi_top
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
    )

ip_sources(${IP} VERILOG
    ${PROJECT_SOURCE_DIR}/top1.v
    ${PROJECT_SOURCE_DIR}/top2.v
    )

iverilog(${IP}
    TOP_MODULE top2
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb
    )

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
