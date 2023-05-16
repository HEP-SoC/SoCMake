function(peakrdl_print RTLLIB)
    # cmake_parse_arguments(ARG "" "" "" ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    add_custom_target(${RTLLIB}_print
        COMMAND peakrdl dump 
            ${RDL_FILES}
        COMMENT "Running peakrdl dump on ${RTLLIB}"
        )

endfunction()


