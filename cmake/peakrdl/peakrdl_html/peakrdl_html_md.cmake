function(peakrdl_html_md IP_LIB)
    cmake_parse_arguments(ARG "SERVER_TARGET" "OUTDIR;HOME_URL" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/html)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_HOME_URL)
        set(ARG_HOME_URL --home-url ${ARG_HOME_URL})
    endif()

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)
    get_ip_sources(MD_FILES ${IP_LIB} MARKDOWN)
    get_ip_sources(GRAPHVIZ_FILES ${IP_LIB} GRAPHVIZ)
    get_ip_sources(GRAPHIC_FILES ${IP_LIB} GRAPHIC)
    list(APPEND GRAPHIC_FILES ${GRAPHVIZ_FILES})

    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD 
        ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/export_html.py
            --rdlfiles ${RDL_FILES}
            --outdir ${OUTDIR} 
            ${ARG_HOME_URL}
            )

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${OUTDIR} ${STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}/docs 
        COMMAND ${CMAKE_COMMAND} -E copy ${MD_FILES} ${OUTDIR}/docs  ||  true # Ignore error if ${MD_FILES} dont exist, TODO something smarter 
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}/docs/pictures 
        COMMAND ${CMAKE_COMMAND} -E copy ${GRAPHIC_FILES} ${OUTDIR}/docs/pictures || true
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES} ${GRAPHIC_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${OUTDIR} ${STAMP_FILE}
        )

    if(ARG_SERVER_TARGET)
        add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_server
            COMMAND python3 -m http.server -d "${OUTDIR}"
            DEPENDS ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            )
    endif()

endfunction()



