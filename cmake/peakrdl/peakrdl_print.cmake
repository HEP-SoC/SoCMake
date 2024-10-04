#[[[
# Creates a target <IP_LIB>_peakrdl_print that prints address map in terminal.
#
#]]
function(peakrdl_print IP_LIB)
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set,
                unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    unset(INCDIRS_ARG)
    foreach(__incdir ${INC_DIRS})
        list(APPEND INCDIRS_ARG -I${__incdir})
    endforeach()

    unset(COMPDEFS_ARG)
    foreach(__compdefs ${COMP_DEFS})
        list(APPEND COMPDEFS_ARG -D${__compdefs})
    endforeach()

    find_python3()
    add_custom_target(${IP_LIB}_peakrdl_print
        COMMAND ${Python3_EXECUTABLE} -m peakrdl dump
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            ${RDL_FILES}
        DEPENDS ${IP_LIB}
        COMMENT "Running peakrdl dump on ${IP_LIB}"
        )
endfunction()
