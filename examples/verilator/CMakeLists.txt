cmake_minimum_required(VERSION 3.25)
project(example CXX C)

include("../../SoCMakeConfig.cmake")

include("deps/deps.cmake")
add_subdirectory(adder)

verilator_build(VERSION 5.012 EXACT_VERSION)

verilator(cern::ip::adder::0.0.1 TRACE)

add_executable(testbench main.cpp)

target_link_libraries(testbench cern::ip::adder::0.0.1::vlt)

help()
