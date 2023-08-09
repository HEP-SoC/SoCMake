# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../sv2v.cmake)
function(yosys IP_LIB)
    cmake_parse_arguments(ARG "SV2V;SHOW;REPLACE" "OUTDIR;TOP" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/yosys)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_TOP)
        get_target_property(TOP_MODULE ${IP_LIB} TOP_MODULE)
        if(NOT TOP_MODULE)
            set(TOP_MODULE ${IP_LIB})
        endif()
    else()
        set(TOP_MODULE ${ARG_TOP})
    endif()

    if(ARG_SV2V AND NOT TARGET ${IP_LIB}_sv2v)
        sv2v(${IP_LIB})
        set(SOURCES ${BINARY_DIR}/sv2v/${IP_LIB}.v)
    else()
        get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
        get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
        list(PREPEND SOURCES ${V_SOURCES})
        list(REMOVE_DUPLICATES SOURCES)
    endif()
    string (REPLACE ";" " " V_FILES_STR "${SOURCES}")

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    set(V_GEN ${OUTDIR}/${IP_LIB}.v)
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)
    get_ip_sources(YOSYS_SCRIPTS ${IP_LIB} YOSYS)
    if(NOT YOSYS_SCRIPTS)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/default.ys.in ${OUTDIR}/flows/default.ys @ONLY)
        set(YOSYS_SCRIPTS ${OUTDIR}/flows/default.ys)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/default.ys)
    endif()

    if(ARG_SHOW)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/show.ys.in ${OUTDIR}/flows/show.ys @ONLY)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/show.ys)
        list(PREPEND YOSYS_SCRIPTS ${OUTDIR}/flows/show.ys)
    endif()


    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND yosys ${CMP_DEFS_ARG} -s ${YOSYS_SCRIPTS}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SOURCES} ${YOSYS_SCRIPTS}
        )

    if(ARG_REPLACE)
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_GEN})
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES "")
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()




