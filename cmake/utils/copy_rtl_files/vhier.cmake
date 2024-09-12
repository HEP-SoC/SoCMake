function(vhier IP_LIB)
    cmake_parse_arguments(ARG "XML;FILES;MODULES;FOREST" "TOP_MODULE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    ip_assume_last(IP_LIB ${IP_LIB})

    get_target_property(IP_NAME ${IP_LIB} IP_NAME)

    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    foreach(_i ${RTL_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} --include ${_i})
    endforeach()

    find_program(VHIER_EXECUTABLE vhier)
    set(__CMD ${VHIER_EXECUTABLE}
        --top-module $<IF:$<BOOL:${ARG_TOP_MODULE}>,${ARG_TOP_MODULE},${IP_NAME}>
        ${RTL_SOURCES}
        $<$<BOOL:${ARG_XML}>:--xml>
        $<$<BOOL:${ARG_FILES}>:--module-files>
        $<$<BOOL:${ARG_MODULES}>:--modules>
        $<$<BOOL:${ARG_FOREST}>:--forest>
    )

    set(OUT_FILE ${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.$<IF:$<BOOL:${ARG_XML}>,xml,txt>)
    set(STAMP_FILE "${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${OUT_FILE}
        COMMAND ${__CMD} | tee ${OUT_FILE}
        COMMENT "Printing verilog hierarchy of ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${IP_LIB} ${STAMP_FILE} ${OUT_FILE}
    )
endfunction()

