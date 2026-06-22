#[[[ @module vhdl
#]]
include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/../utils/socmake_message.cmake")

#[[[
# vhdl-linter tool interface.
#
# This function will create a target for linting the VHDL files, more information about the tool can be found `here <https://github.com/vhdl-linter/vhdl-linter>`_.
# It does support ``vhdl-linter.yml`` configuration file, if you have your own.
#
# It expects that **IP_LIB** has **SOURCES** property set with a list of VHDL files to be used as inputs.
#
# During the linting, errors, warning or informations will be displayed in the terminal.
# No changes will be done to the files and no new files with corrected errors or warning will be produced.
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
#]]
function(vhdl_linter IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})

    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL)
    list(PREPEND SOURCES ${VHDL_SOURCES})

    find_program(VHDL_LINTER_EXECUTABLE vhdl-linter
        PATHS ${VHDL_LINTER_EXECUTABLE} $ENV{VHDL_LINTER_EXECUTABLE}
        )

    if(NOT VHDL_LINTER_EXECUTABLE)
        return()
    endif()

    get_target_property(_SOURCE_DIR ${IP_LIB} SOURCE_DIR)

    set(DESCRIPTION "Lint ${IP_LIB} VHDL with ${CMAKE_CURRENT_FUNCTION}")
    set(STAMP_FILE "${PROJECT_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND ${VHDL_LINTER_EXECUTABLE} ${_SOURCE_DIR}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES} ${IP_LIB}
        COMMENT ${DESCRIPTION}
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${IP_LIB} ${STAMP_FILE}
        )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
    # add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()
