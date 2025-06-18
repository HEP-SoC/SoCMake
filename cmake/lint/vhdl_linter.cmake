include_guard(GLOBAL)

function(vhdl_linter IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
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

    set(STAMP_FILE "${PROJECT_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND ${VHDL_LINTER_EXECUTABLE} ${_SOURCE_DIR}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES} ${IP_LIB}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${ARG_EXECUTABLE} ${IP_LIB} ${STAMP_FILE}
        )
    # add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()
