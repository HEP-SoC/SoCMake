cmake_minimum_required(VERSION 3.27)
project(SoCMake_testing)

include(CTest)

add_custom_target(check
    COMMAND ctest -j${CMAKE_BUILD_PARALLEL_LEVEL} --output-on-failure
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/../../
)

add_custom_target(check_cdash
    COMMAND ctest -D Nightly -j${CMAKE_BUILD_PARALLEL_LEVEL} --output-on-failure
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/../../
)

add_subdirectory(iverilog)
add_subdirectory(peakrdl)
# TODO: add this test once merging into master (CI workflow uses only master branch for testing)
# TODO: add slang v10.0.0 to support it
# add_subdirectory(generate_sources_list)

include("getcmaketest.cmake")
include(cmake_test/cmake_test)

ct_add_dir(add_ip                 USE_REL_PATH_NAMES LABEL)
ct_add_dir(alias_dereference      USE_REL_PATH_NAMES LABEL)
ct_add_dir(check_languages        USE_REL_PATH_NAMES LABEL)
ct_add_dir(get_ip_property        USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_compile_definitions USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_include_directories USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_link                USE_REL_PATH_NAMES LABEL)
ct_add_dir(ip_sources             USE_REL_PATH_NAMES LABEL)
ct_add_dir(ipxact                 USE_REL_PATH_NAMES LABEL)
ct_add_dir(utils                  USE_REL_PATH_NAMES LABEL)
ct_add_dir(vlnv                   USE_REL_PATH_NAMES LABEL)
