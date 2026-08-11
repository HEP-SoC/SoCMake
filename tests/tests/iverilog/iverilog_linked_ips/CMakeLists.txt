cmake_minimum_required(VERSION 3.27)
project(iverilog_linked_ips NONE)

# mod_ip provides the module under test
add_ip(iverilog_mod_ip
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
)
ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/mod.v)
set(MOD_IP ${IP})

# tb_ip contains the testbench; it instantiates the module from mod_ip
add_ip(iverilog_linked_ips
    VENDOR tests
    LIBRARY iverilog
    VERSION 1
)
ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb.v)
ip_link(${IP} ${MOD_IP})

iverilog(${IP} EXECUTABLE ${PROJECT_BINARY_DIR}/tb)

include(CTest)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/tb)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
