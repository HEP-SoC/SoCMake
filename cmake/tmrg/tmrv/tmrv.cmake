function(tmrv RTLLIB)
    cmake_parse_arguments(ARG "REPLACE" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/tmrv)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_rtl_target_sources(V_FILES ${RTLLIB})
    list(REMOVE_DUPLICATES V_FILES)

    get_rtl_target_incdirs(INCDIRS ${RTLLIB})
    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    # TODO get verilog defines

    foreach(v ${V_FILES})
        get_filename_component(base_name ${v} NAME_WE)
        get_filename_component(ext ${v} EXT)
        list(APPEND V_GEN ${OUTDIR}/${base_name}Voted${ext})
    endforeach()

    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${V_GEN}
        COMMAND python -m tmrv
        ${V_FILES} 
        -o ${OUTDIR}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${V_FILES} ${V_GEN}
        )

    if(ARG_REPLACE)
        set_property(TARGET ${RTLLIB} PROPERTY SOURCES ${V_GEN})
        set_property(TARGET ${RTLLIB} PROPERTY INTERFACE_SOURCES "")
        add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()





