include("../../../../SoCMakeConfig.cmake")
include("../../../utils/test_utils.cmake")

cmake_minimum_required(VERSION 3.27)
project(test NONE)

### A simple test with default arguments
add_ip(html_ip)

ip_sources(${IP} SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/ip1.rdl
    )
ip_include_directories(${IP} SYSTEMRDL
    ${PROJECT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/inc
    )
ip_compile_definitions(${IP} SYSTEMRDL
    TEST1=123
    -DTEST2=asd
    )

peakrdl_html(${IP})

include(CTest)
enable_testing()

find_python3()
add_test_makefile_rule_match_patterns(${IP}_peakrdl_html
    "${Python3_EXECUTABLE} -m peakrdl html"
    "-I${PROJECT_SOURCE_DIR}/inc"
    "-I${PROJECT_SOURCE_DIR}"
    "-DTEST1=123"
    "-DTEST2=asd"
    "-o ${PROJECT_BINARY_DIR}/${IP}_peakrdl_html"
    "${PROJECT_SOURCE_DIR}/ip1.rdl"
    )
set_property(TEST ${CTEST_NAME} PROPERTY LABELS peakrdl)


### A test with arguments
add_ip(html_ip2)

ip_sources(${IP} SYSTEMRDL
    ${PROJECT_SOURCE_DIR}/ip1.rdl
    )

peakrdl_html(${IP}
    OUTDIR ${PROJECT_BINARY_DIR}/ip2_html
    SERVER_TARGET
    ARGS --show-signals
         --home-url "https://www.google.com"
    )

add_test_makefile_rule_match_patterns(${IP}_peakrdl_html
    "${Python3_EXECUTABLE} -m peakrdl html"
    "-o ${PROJECT_BINARY_DIR}/ip2_html"
    "${PROJECT_SOURCE_DIR}/ip1.rdl"
    "--show-signals"
    "--home-url https://www.google.com"
    )
set_property(TEST ${CTEST_NAME} PROPERTY LABELS peakrdl)

add_test_makefile_rule_match_patterns(${IP}_peakrdl_html_server
    "cd ${PROJECT_BINARY_DIR}/ip2_html && ${Python3_EXECUTABLE} -m http.server"
    )
set_property(TEST ${CTEST_NAME} PROPERTY LABELS peakrdl)
