cmake_minimum_required(VERSION 3.25)
project(systemc_example CXX)

include("../../SoCMakeConfig.cmake")

systemc_build(VERSION 3.0.0 EXACT_VERSION)

add_executable(systemc_example
    sc_main.cpp
    )

target_link_libraries(systemc_example PUBLIC
    SystemC::systemc)

add_custom_target(run_systemc_example
    COMMAND systemc_example)
