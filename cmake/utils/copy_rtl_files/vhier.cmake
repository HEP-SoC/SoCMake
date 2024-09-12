function(vhier IP_LIB)
    cmake_parse_arguments(ARG "XML;FILES;MODULES;FOREST" "TOP_MODULE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    ip_assume_last(IP_LIB ${IP_LIB})

    get_target_property(IP_NAME ${IP_LIB} IP_NAME)

    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    get_ip_include_directories(SV_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(V_INCDIRS ${IP_LIB} VERILOG)
    foreach(_i ${SV_INCDIRS} ${V_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} -y ${_i})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    foreach(_d ${COMP_DEFS_SV} ${COMP_DEFS_V})
        set(COMPDEF_ARG ${COMPDEF_ARG} -D${_d})
    endforeach()

    find_program(VHIER_EXECUTABLE vhier)
    set(__CMD ${VHIER_EXECUTABLE}
        --top-module $<IF:$<BOOL:${ARG_TOP_MODULE}>,${ARG_TOP_MODULE},${IP_NAME}>
        ${RTL_SOURCES}
        ${INCDIR_ARG}
        ${COMPDEF_ARG}
        $<$<BOOL:${ARG_XML}>:--xml>
        $<$<BOOL:${ARG_FILES}>:--module-files>
        $<$<BOOL:${ARG_MODULES}>:--modules>
        $<$<BOOL:${ARG_FOREST}>:--forest>
    )

    set(OUT_FILE ${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.$<IF:$<BOOL:${ARG_XML}>,xml,txt>)
    set(STAMP_FILE "${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${OUT_FILE}
        COMMAND touch ${STAMP_FILE}
        COMMAND ${__CMD} | tee ${OUT_FILE}
        DEPENDS ${RTL_SOURCES} ${IP_LIB}
        COMMENT "Printing verilog hierarchy of ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${IP_LIB} ${STAMP_FILE} ${OUT_FILE}
    )
endfunction()

