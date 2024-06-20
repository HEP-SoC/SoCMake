include_guard(GLOBAL)

function(list_syn_src IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    # Get sources
    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})
    
    get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
    
    add_custom_command(
        OUTPUT ${OUTDIR}/manifest
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/manifest_gen.py -t ${TOP_MODULE} -f ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${OUTDIR}/manifest
    )

endfunction()