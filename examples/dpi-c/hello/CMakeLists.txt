cmake_minimum_required(VERSION 3.25)
project(hello_dpi CXX)

set(CMAKE_CXX_STANDARD 11)

add_library(hello_dpi SHARED
    ./hello.cpp)

if(SIMULATOR STREQUAL "modelsim")
    target_compile_options(hello_dpi PRIVATE -m32)
    target_link_options(hello_dpi PRIVATE -m32)
endif() 

if(NOT SIMULATOR STREQUAL "verilator")
    target_link_libraries(hello_dpi PRIVATE
        SoCMake::DPI-C
    )
endif()
