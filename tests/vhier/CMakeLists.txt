include("../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)
project(vhier_test)

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

vhier(${IP} FILES MODULES XML)

include(CTest)

add_test(NAME ${PROJECT_NAME} 
    COMMAND /bin/bash -c "make ${IP}_vhier && sed -i 's#${CMAKE_CURRENT_LIST_DIR}/##g' ${CMAKE_BINARY_DIR}/${IP}_vhier.xml && diff ${CMAKE_BINARY_DIR}/${IP}_vhier.xml ${CMAKE_CURRENT_LIST_DIR}/golden.xml"
    # Need to do sed to make relative file paths, because of the golden.xml that was generated (and sed) on my filesystem, in CI it would be different
    )
