include_guard(GLOBAL)

function(sv2v IP_LIB)
    cmake_parse_arguments(ARG "REPLACE" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/sv2v)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(INCDIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG)

    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    set(V_GEN ${OUTDIR}/${IP_LIB}.v)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    set(DESCRIPTION "Convert ${IP_LIB} System Verilog files to Verilog with ${CMAKE_CURRENT_FUNCTION}")

    add_custom_command(
        OUTPUT ${STAMP_FILE} ${V_GEN}
        COMMAND  sv2v
        ${SOURCES} ${INCDIR_ARG} ${CMP_DEFS_ARG}
        -w ${V_GEN}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT ${DESCRIPTION}
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SOURCES} ${V_GEN}
        )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

    if(ARG_REPLACE)
        get_property(__flat_graph TARGET ${IP_LIB} PROPERTY FLAT_GRAPH)
        foreach(ip ${__flat_graph})
            ip_sources(${ip} SYSTEMVERILOG REPLACE  "")
        endforeach()

        ip_sources(${IP_LIB} VERILOG ${V_GEN})
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()
