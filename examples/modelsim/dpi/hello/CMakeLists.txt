cmake_minimum_required(VERSION 3.25)
project(hello_dpi CXX)

add_library(hello_dpi SHARED
    ./hello.cpp
    )

target_compile_options(hello_dpi PRIVATE -m32)
target_link_options(hello_dpi PRIVATE -m32)
