function(peakrdl_print IP_LIB)
    # cmake_parse_arguments(ARG "" "" "" ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    add_custom_target(${IP_LIB}_print
        COMMAND ${Python3_EXECUTABLE} -m peakrdl dump 
            ${RDL_FILES}
        COMMENT "Running peakrdl dump on ${IP_LIB}"
        )

endfunction()


