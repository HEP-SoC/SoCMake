function(gen_lds IP_LIB)
    cmake_parse_arguments(ARG "NODEBUG" "OUTDIR" "PARAMETERS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../fw_utils.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    set(LDS_GEN_TOOL "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/src/gen_linker_script.py")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

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

    # Used to overwrite the top level parameters
    set(OVERWRITTEN_PARAMETERS "")
    if(ARG_PARAMETERS)
        foreach(PARAM ${ARG_PARAMETERS})
            string(APPEND OVERWRITTEN_PARAMETERS "-p${PARAM}")
        endforeach()
    endif()

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()
    set(LDS_FILE "${OUTDIR}/${IP_LIB}.lds")

    set_source_files_properties(${LDS_FILE} PROPERTIES GENERATED TRUE)
    ip_sources(${IP_LIB} LINKER_SCRIPT ${LDS_FILE})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${LDS_FILE} ${STAMP_FILE}
        COMMAND ${Python3_EXECUTABLE} ${LDS_GEN_TOOL}
            --rdlfiles ${RDL_FILES}
            --outfile ${LDS_FILE}
            ${ARG_NODEBUG}
            ${OVERWRITTEN_PARAMETERS}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_lds
        DEPENDS ${RDL_FILES} ${STAMP_FILE}
        )

    add_dependencies(${IP_LIB} ${IP_LIB}_lds)

endfunction()

include("${CMAKE_CURRENT_LIST_DIR}/src/lds_props.cmake")
