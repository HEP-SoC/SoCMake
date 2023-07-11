function(tmrg RTLLIB)
    cmake_parse_arguments(ARG "REPLACE;SED_WOR;NO_COMMON_DEFINITIONS" "OUTDIR" "" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/tmrg)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_rtl_target_sources(V_FILES ${RTLLIB})
    list(REMOVE_DUPLICATES V_FILES)

    foreach(vfile ${V_FILES})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        get_filename_component(V_SOURCE_EXT ${vfile} EXT)
        list(APPEND V_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}TMR${V_SOURCE_EXT}")
        # execute_process(COMMAND touch ${V_GEN}) # TODO Needed???
    endforeach()
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    set(TMRG_COMMAND 
        tmrg --stats --tmr-dir=${OUTDIR} ${V_FILES};
        )

    if(ARG_SED_WOR)
        set(SED_COMMAND
            COMMAND sed -i "s/wor/wire/g" ${V_GEN}
            )
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${STAMP_FILE}
        COMMAND ${TMRG_COMMAND}
        ${SED_COMMAND}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${V_FILES} ${V_GEN}
        )

    if(ARG_REPLACE)
        get_target_property(TOP_MODULE ${RTLLIB} TOP_MODULE)
        if(NOT TOP_MODULE)
            set_property(TARGET ${RTLLIB} PROPERTY TOP_MODULE ${RTLLIB}TMR)
        else()
            set_property(TARGET ${RTLLIB} PROPERTY TOP_MODULE ${TOP_MODULE}TMR)
        endif()

        set_property(TARGET ${RTLLIB} PROPERTY SOURCES ${V_GEN})
        set_property(TARGET ${RTLLIB} PROPERTY INTERFACE_SOURCES "")
        add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()

