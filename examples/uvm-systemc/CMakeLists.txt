cmake_minimum_required(VERSION 3.25)
project(uvm-systemc_example CXX C)

include("../../SoCMakeConfig.cmake")

systemc_build(VERSION 3.0.0 EXACT_VERSION)
uvm_systemc_build(VERSION 1.0-beta6)

add_executable(systemc_example
    hello_world.cpp
    )
target_include_directories(systemc_example PUBLIC
    .
    )

target_link_libraries(systemc_example PUBLIC
    SystemC::systemc
    UVM-SystemC::shared)

add_custom_target(run_systemc_example
    COMMAND systemc_example)
