include("../../../../SoCMakeConfig.cmake")
include("../../../utils/test_utils.cmake")

cmake_minimum_required(VERSION 3.27)
project(test NONE)

### A simple test with default arguments
add_ip(regblock_ip)

ip_sources(${IP} SYSTEMRDL
    ${CMAKE_CURRENT_LIST_DIR}/ip.rdl
    )

peakrdl_regblock(${IP})

include(CTest)
enable_testing()

find_python3()
add_test_makefile_rule_match_patterns(${IP}_peakrdl_regblock
    "${Python3_EXECUTABLE} -m peakrdl regblock"
    "--rename ${IP_NAME}_regblock"
    "--cpuif apb3-flat"
    "-o ${PROJECT_BINARY_DIR}/${IP}_peakrdl_regblock"
    "${CMAKE_CURRENT_LIST_DIR}/ip.rdl"
    )
set_property(TEST ${CTEST_NAME} PROPERTY LABELS peakrdl)

##### Test with mutliple arguments
add_ip(regblock_ip2)

ip_sources(${IP} SYSTEMRDL
    ${CMAKE_CURRENT_LIST_DIR}/ip2.rdl
    )

ip_link(regblock_ip2 regblock_ip)

peakrdl_regblock(${IP}
    OUTDIR ${PROJECT_BINARY_DIR}/ip2_regblock
    INTF axi4-lite
    RENAME random_ip
    RESET arst_n
    ARGS --addr-width 8
         --rt-read-response
    )

include(CTest)
enable_testing()

find_python3()
add_test_makefile_rule_match_patterns(${IP}_peakrdl_regblock
    "${Python3_EXECUTABLE} -m peakrdl regblock"
    "--rename random_ip"
    "--cpuif axi4-lite"
    "--default-reset arst_n"
    "--addr-width 8"
    "--rt-read-response"
    "-o ${PROJECT_BINARY_DIR}/ip2_regblock"
    "${CMAKE_CURRENT_LIST_DIR}/ip.rdl ${CMAKE_CURRENT_LIST_DIR}/ip2.rdl" # Keep them in single string to enforce order
    )
set_property(TEST ${CTEST_NAME} PROPERTY LABELS peakrdl)
