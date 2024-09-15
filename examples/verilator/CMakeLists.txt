cmake_minimum_required(VERSION 3.25)
project(example CXX C)

include("deps/deps.cmake")
add_subdirectory(adder)

verilator(cern::ip::adder::0.0.1 TRACE)

add_executable(testbench main.cpp)

target_link_libraries(testbench cern::ip::adder::0.0.1::vlt)

help()
