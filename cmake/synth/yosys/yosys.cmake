include(${CMAKE_CURRENT_LIST_DIR}/../sv2v.cmake)
function(yosys RTLLIB)
    cmake_parse_arguments(ARG "SV2V;SHOW;REPLACE" "OUTDIR;TOP" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/yosys)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_TOP)
        get_target_property(TOP_MODULE ${RTLLIB} TOP_MODULE)
        if(NOT TOP_MODULE)
            set(TOP_MODULE ${RTLLIB})
        endif()
    else()
        set(TOP_MODULE ${ARG_TOP})
    endif()

    if(ARG_SV2V AND NOT TARGET ${RTLLIB}_sv2v)
        sv2v(${RTLLIB})
        set(V_FILES ${BINARY_DIR}/sv2v/${RTLLIB}.v)
    else()
        get_rtl_target_sources(V_FILES ${RTLLIB})
        list(REMOVE_DUPLICATES V_FILES)
    endif()
    string (REPLACE ";" " " V_FILES_STR "${V_FILES}")

    set(V_GEN ${OUTDIR}/${RTLLIB}.v)
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    get_target_property(YOSYS_SCRIPTS ${RTLLIB} YOSYS_SCRIPTS)
    if(NOT YOSYS_SCRIPTS)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/default.ys.in ${OUTDIR}/flows/default.ys @ONLY)
        set(YOSYS_SCRIPTS ${OUTDIR}/flows/default.ys)
        set_property(TARGET ${RTLLIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/default.ys)
    endif()

    if(ARG_SHOW)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/show.ys.in ${OUTDIR}/flows/show.ys @ONLY)
        set_property(TARGET ${RTLLIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/show.ys)
        list(PREPEND YOSYS_SCRIPTS ${OUTDIR}/flows/show.ys)
    endif()


    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND yosys -s ${YOSYS_SCRIPTS}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${V_FILES} ${YOSYS_SCRIPTS}
        )

    if(ARG_REPLACE)
        set_property(TARGET ${RTLLIB} PROPERTY SOURCES ${V_GEN})
        set_property(TARGET ${RTLLIB} PROPERTY INTERFACE_SOURCES "")
        add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()




