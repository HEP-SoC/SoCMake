cmake_minimum_required(VERSION 3.25)
project(SoCMake_testing)

include(CTest)

add_custom_target(check
    COMMAND ctest $(JOBS) --output-on-failure
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/../
    )

add_custom_target(check_cdash
    COMMAND ctest -D Nightly $(JOBS) --output-on-failure
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/../
    )

add_subdirectory(iverilog)
add_subdirectory(vhier)
add_subdirectory(peakrdl)

include("getcmaketest.cmake")
include(cmake_test/cmake_test)

ct_add_dir(add_ip                 USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_include_directories USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_compile_definitions USE_REL_PATH_NAMES LABEL)
ct_add_dir(alias_dereference      USE_REL_PATH_NAMES LABEL)
ct_add_dir(check_languages        USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_sources             USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_link                USE_REL_PATH_NAMES LABEL)
