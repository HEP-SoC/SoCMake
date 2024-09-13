cmake_minimum_required(VERSION 3.25)
project(iverilog_multitop NONE)

add_ip(iverilog_multitop
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
    )

ip_sources(${IP} VERILOG
    ${PROJECT_SOURCE_DIR}/top1.v
    ${PROJECT_SOURCE_DIR}/top2.v
    )

iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb
    )

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)

add_dependencies(check ${IP}_iverilog)
