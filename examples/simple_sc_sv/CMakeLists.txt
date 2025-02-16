cmake_minimum_required(VERSION 3.25)
project(simple_sc_sv_example C CXX)

include("../../SoCMakeConfig.cmake")

systemc_build(VERSION 3.0.0 EXACT_VERSION)

add_subdirectory(adder)

verilator(adder SYSTEMC
    VERILATOR_ARGS --pins-sc-uint
    )

add_executable(simple_sc_sv_example 
    ./sc_main.cpp
    )

target_link_libraries(${PROJECT_NAME} PRIVATE
    # External libraries
    SystemC::systemc

    # Verilated HDL
   adder__vlt 
    )

target_compile_definitions(${PROJECT_NAME} PRIVATE
    VERBOSE
    )

help()

