# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../sv2v.cmake)
function(yosys IP_LIB)
    cmake_parse_arguments(ARG "SV2V;SHOW;REPLACE" "OUTDIR;TOP;PLUGINS;SCRIPTS" "" ${ARGN})
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
            get_target_property(IP_NAME ${IP_LIB} IP_NAME)
            set(TOP_MODULE ${IP_NAME})
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

    if(NOT ARG_SCRIPTS)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/default.ys.in ${OUTDIR}/flows/default.ys @ONLY)
        set(YOSYS_SCRIPTS ${OUTDIR}/flows/default.ys)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/default.ys)
    else()
        foreach(_script ${ARG_SCRIPTS})
            get_filename_component(__ext ${_script} EXT)
            get_filename_component(__fn ${_script} NAME_WLE)
            if(__ext STREQUAL ".ys.in")
                configure_file(${_script} ${OUTDIR}/flows/${__fn} @ONLY)
                set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/${__fn})
                list(APPEND YOSYS_SCRIPTS ${OUTDIR}/flows/${__fn})
            endif()
        endforeach()
    endif()

    if(ARG_SHOW)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/show.ys.in ${OUTDIR}/flows/show.ys @ONLY)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/show.ys)
        list(PREPEND YOSYS_SCRIPTS ${OUTDIR}/flows/show.ys)
    endif()

    if(ARG_PLUGINS)
        unset(__PLUGINS_ARG)
        foreach(plugin ${ARG_PLUGINS})
            get_target_property(__type ${plugin} TYPE)
            # get_target_property(_location ${plugin} LOCATION)
            # message("LOCATION IS: $<TARGET_FILE:${plugin}>")
            # get_target_property(CONFIGURATION cern::yosys::reglist IMPORTED_CONFIGURATIONS)
            if(${__type} STREQUAL "SHARED_LIBRARY" OR ${__type} STREQUAL "STATIC_LIBRARY")
                list(APPEND __PLUGINS_ARG -m $<TARGET_FILE:${plugin}>)
            else()
                message(FATAL_ERROR "Only Shared and Static libraries are supported for Yosys PLUGINS at the moment")
            endif()
        endforeach()
    endif()


    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND yosys ${CMP_DEFS_ARG} -s ${YOSYS_SCRIPTS} ${__PLUGINS_ARG}
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




