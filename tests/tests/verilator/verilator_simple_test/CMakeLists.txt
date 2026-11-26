cmake_minimum_required(VERSION 3.27)
project(verilator_simple_test NONE)

add_ip(verilator_simple_test
    VENDOR tests
    LIBRARY verilator
    VERSION 1.2.3
)

ip_sources(${IP} SYSTEMVERILOG
    ${PROJECT_SOURCE_DIR}/tb.sv
)

ip_compile_definitions(${IP} SYSTEMVERILOG SOME_DEF1=100)
ip_include_directories(${IP} SYSTEMVERILOG ${PROJECT_SOURCE_DIR}/inc)

verilator(${IP}
    MAIN
    TOP_MODULE tb
    EXECUTABLE_NAME tb
    NO_RUN_TARGET
)

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)
set_property(TEST ${PROJECT_NAME} PROPERTY PASS_REGULAR_EXPRESSION "PASS: ")

add_dependencies(check tb)
add_dependencies(check_cdash tb)
