cmake_minimum_required(VERSION 3.25)
project(hello_dpi CXX)

set(CMAKE_CXX_STANDARD 11)

add_library(hello_dpi SHARED
    ./hello.cpp)

target_link_libraries(hello_dpi PRIVATE
    SoCMake::DPI-C
)
