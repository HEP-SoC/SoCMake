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

# top_split: a DEFAULT-file-set top module instantiating a GENERIC-file-set module which, in turn, `includes a
# DEFAULT-file-set header. Exercises SPLIT_FILE_SETS: slang must see the full DEFAULT+GENERIC combination to resolve
# both the module instantiation and the include, while the output is still divided into a DEFAULT-only pair
# (rtl_sources.f/include_sources.f) and a GENERIC-only pair (rtl_sources_split.f/include_sources_split.f).
add_ip(top_split
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
)

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/top_split.sv
    HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/rtl/shared_defines.svh
)

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
)

ip_sources(${IP} SYSTEMVERILOG FILE_SET GENERIC
    ${CMAKE_CURRENT_LIST_DIR}/rtl_generic/generic_mod.sv
)

ip_include_directories(${IP} SYSTEMVERILOG FILE_SET GENERIC
    ${CMAKE_CURRENT_LIST_DIR}/rtl_generic
)

generate_sv_sources_list(${IP}
    TOP_MODULE ${IP_NAME}
    OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${IP_NAME}_sources
    FILE_SETS DEFAULT GENERIC
    SPLIT_FILE_SETS GENERIC
)

add_test(
    NAME ${PROJECT_NAME}_${IP_NAME}
    COMMAND
        # SPLIT_FILE_SETS leaves internal, dot-prefixed intermediate files (raw slang output, allow-lists) alongside
        # the public rtl_sources*.f/include_sources*.f files in OUTDIR; -x '.*' excludes them, since they aren't part
        # of the function's output contract.
        /bin/bash -c
        "make test__ip__${IP_NAME}__0.0.1_source_list && diff -r -x '.*' ${CMAKE_BINARY_DIR}/${IP_NAME}_sources ${CMAKE_CURRENT_LIST_DIR}/golden/${IP_NAME}_sources"
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
