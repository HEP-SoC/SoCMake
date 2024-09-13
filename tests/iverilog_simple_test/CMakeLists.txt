cmake_minimum_required(VERSION 3.25)
project(iverilog_simple_test NONE)

add_ip(iverilog_simple_test
    VENDOR tests
    LIBRARY iverilog
    VERSION 1.2.3
    )

ip_sources(${IP} VERILOG
    ${PROJECT_SOURCE_DIR}/tb.v
    )

ip_compile_definitions(${IP} VERILOG SOME_DEF1=100)
ip_include_directories(${IP} VERILOG ${PROJECT_SOURCE_DIR}/inc)

iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb
    )

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)

add_dependencies(check ${IP}_iverilog)
