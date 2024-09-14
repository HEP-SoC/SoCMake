include("../../../SoCMakeConfig.cmake")
cmake_minimum_required(VERSION 3.25)
project(peakrdl_print_test NONE)

#########
## UDP ##
#########

add_ip(udp
    VENDOR tests
    LIBRARY peakrdl
    VERSION 0.0.1
    )

ip_include_directories(tests::peakrdl::udp SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/include
    )

#########
## IP1 ##
#########

add_ip(ip1
    VENDOR tests
    LIBRARY peakrdl
    VERSION 0.0.1
    )

ip_sources(tests::peakrdl::ip1 SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/ip1.rdl
    )

ip_link(tests::peakrdl::ip1
    tests::peakrdl::udp
    )

#########
## IP2 ##
#########

add_ip(ip2
    VENDOR tests
    LIBRARY peakrdl
    VERSION 0.0.1
    )

ip_sources(tests::peakrdl::ip2 SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/ip2.rdl
    )

ip_link(tests::peakrdl::ip2
    tests::peakrdl::ip1
    )

#########
## TOP ##
#########

add_ip(top
    VENDOR tests
    LIBRARY peakrdl
    VERSION 0.0.1
    )

ip_sources(tests::peakrdl::top SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/top.rdl
    )

ip_link(tests::peakrdl::top
    tests::peakrdl::ip2
    tests::peakrdl::udp
    )

ip_compile_definitions(tests::peakrdl::top SYSTEMRDL
    USE_IP1
    )

#############
## TARGETS ##
#############

peakrdl_print(tests::peakrdl::top)

include(CTest)

add_test(NAME ${PROJECT_NAME} 
    COMMAND /bin/bash -c "diff <(make ${IP}_peakrdl_print | sed -e 's/\\x1b\[[0-9;]*m//g') <(cat  ${CMAKE_CURRENT_LIST_DIR}/golden.txt)"
    # Diff with golden, and ignore colours in make output with sed command
    )
set_property(TEST ${PROJECT_NAME} PROPERTY LABELS peakrdl)
