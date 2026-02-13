# Test relative source file paths, the behaviour is matching the CMake behaviour of target_sources:
# Changed in version 3.13: Relative source file paths are interpreted as being relative to the current source directory (i.e. CMAKE_CURRENT_SOURCE_DIR). See policy CMP0076.

cmake_minimum_required(VERSION 3.27)
project(ip_sources_rel_path NONE)

include("../../../../../SoCMakeConfig.cmake")

add_ip(ip)

set(SV_SOURCES
    file.sv
    file2.sv
    justdir/file3.sv
    )

ip_sources(ip SYSTEMVERILOG
    ${SV_SOURCES}
    )

set(VHDL_SOURCES
    file.vhdl
    file2.vhdl
    justdir/file3.vhdl
    )
ip_sources(ip VHDL
    ${VHDL_SOURCES}
    )

add_subdirectory(otherdir)
include(incdir/incdir.cmake_)

get_ip_sources(SV_ABS_SOURCES ip SYSTEMVERILOG)
get_ip_sources(VHDL_ABS_SOURCES ip VHDL)

set(LANGS "SV;VHDL")
foreach(lang ${LANGS})
    foreach(abspath relpath IN ZIP_LISTS ${lang}_ABS_SOURCES ${lang}_SOURCES)
        if(NOT "${CMAKE_CURRENT_SOURCE_DIR}/${relpath}" PATH_EQUAL ${abspath})
            message(FATAL_ERROR "NOT EQUAL: ${relpath} - ${abspath}")
        endif()

    endforeach()
endforeach()
