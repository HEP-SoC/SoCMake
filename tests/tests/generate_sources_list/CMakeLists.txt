include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)
project(generate_sources_list_test)

add_subdirectory("ips/mod1")

add_ip(top
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
)

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/top.sv
)

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
)

ip_link(${IP} test::ip::mod1)

generate_sv_sources_list(${IP}
    TOP_MODULE ${IP_NAME}
    OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${IP_NAME}_sources
)

include(CTest)

add_test(
    NAME ${PROJECT_NAME}_${IP_NAME}
    COMMAND
        /bin/bash -c
        "make test__ip__${IP_NAME}__0.0.1_source_list && diff -r ${CMAKE_BINARY_DIR}/${IP_NAME}_sources ${CMAKE_CURRENT_LIST_DIR}/golden/${IP_NAME}_sources"
)

add_ip(top_synthesis
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
)

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/top.sv
)

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
)

ip_link(${IP} test::ip::mod1)

generate_sv_sources_list(${IP}
    TOP_MODULE ${IP_NAME}
    OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${IP_NAME}_sources
    SLANG_ARGS -DSYNTHESIS
)

add_test(
    NAME ${PROJECT_NAME}_${IP_NAME}
    COMMAND
        /bin/bash -c
        "make test__ip__${IP_NAME}__0.0.1_source_list && diff -r ${CMAKE_BINARY_DIR}/${IP_NAME}_sources ${CMAKE_CURRENT_LIST_DIR}/golden/${IP_NAME}_sources"
)
