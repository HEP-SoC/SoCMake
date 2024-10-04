function(peakrdl_docusaurus IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;SIDEBAR_TEMPLATE;LOGO" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/docusaurus)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_SIDEBAR_TEMPLATE)
        set(_ARG_SIDEBAR_TEMPLATE --sidebar-template ${ARG_SIDEBAR_TEMPLATE})
    else()
        unset(_ARG_SIDEBAR_TEMPLATE)
    endif()

    if(ARG_LOGO)
        set(_ARG_LOGO --logo ${ARG_LOGO})
    else()
        unset(_ARG_LOGO)
    endif()

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
    set(__CMD
        ${Python3_EXECUTABLE} -m peakrdl docusaurus
            -o ${OUTDIR}
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            ${RDL_FILES}
            ${_ARG_SIDEBAR_TEMPLATE}
            ${_ARG_LOGO}
        )

    get_ip_sources(MARKDOWN_FILES ${IP_LIB} MARKDOWN)
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES} ${ARG_SIDEBAR_TEMPLATE} ${ARG_LOGO} ${MARKDOWN_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE}
        )

endfunction()

