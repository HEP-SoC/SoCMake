# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
include_guard(GLOBAL)

function(sv2v IP_LIB)
    cmake_parse_arguments(ARG "REPLACE" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/sv2v)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    get_ip_include_directories(INCDIRS ${IP_LIB})
    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    # TODO get verilog defines

    set(V_GEN ${OUTDIR}/${IP_LIB}.v)

    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)


    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${V_GEN}
        COMMAND  sv2v
        ${SOURCES} ${INCDIR_ARG}
        -w ${V_GEN}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SOURCES} ${V_GEN}
        )

    if(ARG_REPLACE)
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_GEN})
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES "")
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()




