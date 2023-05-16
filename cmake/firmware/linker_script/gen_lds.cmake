function(gen_lds RTLLIB)
    cmake_parse_arguments(ARG "NODEBUG" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../fw_utils.cmake")

    set(LDS_GEN_TOOL "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/src/gen_linker_script.py")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/lds)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_NODEBUG)
        set(ARG_NODEBUG)
    else()
        set(ARG_NODEBUG --debug)
    endif()

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()
    set(LDS_FILE "${OUTDIR}/${RTLLIB}.lds")

    set_source_files_properties(${LDS_FILE} PROPERTIES GENERATED TRUE)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY LDS_FILES ${LDS_FILE})

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${LDS_FILE} ${STAMP_FILE}
        COMMAND python3 ${LDS_GEN_TOOL}
            --rdlfiles ${RDL_FILES}
            --outfile ${LDS_FILE}
            ${ARG_NODEBUG}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_lds
        DEPENDS ${RDL_FILES} ${STAMP_FILE}
        )

    add_dependencies(${RTLLIB} ${RTLLIB}_lds)

endfunction()


