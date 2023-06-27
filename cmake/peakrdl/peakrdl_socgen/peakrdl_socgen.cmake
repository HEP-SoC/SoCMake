include("${CMAKE_CURRENT_LIST_DIR}/common/socgen_props.cmake")

function(peakrdl_socgen RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/socgen)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_rtl_target_property(RDL_SOCGEN_GLUE ${RTLLIB} RDL_SOCGEN_GLUE)
    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    # Call peakrdl-socgen with --list-files option to get the list of headers
    execute_process(
        OUTPUT_VARIABLE V_GEN
        ERROR_VARIABLE SOCGEN_ERROR
        COMMAND peakrdl socgen
            --list-files
            ${RDL_FILES}
            -o ${OUTDIR}
        )
    if(V_GEN)
        string(REPLACE " " ";" V_GEN "${V_GEN}")
        string(REPLACE "\n" "" V_GEN "${V_GEN}")
        list(REMOVE_DUPLICATES V_GEN)
    else()
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${RTLLIB}, output of --list-files option: ${V_GEN} error output: ${SOCGEN_ERROR}")
    endif()

    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY SOURCES ${V_GEN})

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${STAMP_FILE}
        COMMAND peakrdl socgen 
        --intfs ${RDL_SOCGEN_GLUE}
            -o ${OUTDIR} 
            ${RDL_FILES}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_socgen
        DEPENDS ${V_GEN} ${STAMP_FILE}
        )

    add_dependencies(${RTLLIB} ${RTLLIB}_socgen)

endfunction()

