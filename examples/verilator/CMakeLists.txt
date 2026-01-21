cmake_minimum_required(VERSION 3.25)
project(example CXX C)

include("../../SoCMakeConfig.cmake")

add_subdirectory(adder)

verilator_build(VERSION 5.022)

verilator(adder TRACE)

add_executable(testbench main.cpp)

target_link_libraries(testbench adder::vlt)

add_custom_target(run_tb_verilator
    COMMAND testbench)

help()
