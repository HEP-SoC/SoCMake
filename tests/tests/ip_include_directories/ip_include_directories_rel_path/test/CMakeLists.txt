# Test relative include directories paths, the behaviour is matching the CMake behaviour of target_include_directories():
# Changed in version 3.13: Relative source file paths are interpreted as being relative to the current source directory (i.e. CMAKE_CURRENT_SOURCE_DIR). See policy CMP0076.

cmake_minimum_required(VERSION 3.28)
project(ip_include_directories_rel_path NONE)

include("../../../../../SoCMakeConfig.cmake")

add_ip(ip)

set(SV_INCDIRS
    .
    justdir
    )
ip_include_directories(ip SYSTEMVERILOG
    ${SV_INCDIRS}
    )

add_subdirectory(otherdir)
include(incdir/incdir.cmake_)

get_ip_include_directories(SV_ABS_INCDIRS ip SYSTEMVERILOG)

foreach(abspath relpath IN ZIP_LISTS SV_ABS_INCDIRS SV_INCDIRS)
    # If there is only . at the end, remove it, otherwise it wont match
    string(REGEX REPLACE "\\.$" "" relpath ${relpath})
    if(NOT "${CMAKE_CURRENT_SOURCE_DIR}/${relpath}" PATH_EQUAL ${abspath})
        message(FATAL_ERROR "NOT EQUAL: ${CMAKE_CURRENT_SOURCE_DIR}/${relpath} - ${abspath}")
    endif()

endforeach()
