# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
include_guard(GLOBAL)

function(tmrv IP_LIB)
    cmake_parse_arguments(ARG "REPLACE" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/tmrv)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG)
    list(PREPEND SOURCES ${V_SOURCES})
    list(REMOVE_DUPLICATES SOURCES)

    get_ip_include_directories(INCDIRS ${IP_LIB} VERILOG SYSTEMVERILOG)
    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    # TODO get verilog defines

    foreach(v ${SOURCES})
        get_filename_component(base_name ${v} NAME_WE)
        get_filename_component(ext ${v} EXT)
        list(APPEND V_GEN ${OUTDIR}/${base_name}Voted${ext})
    endforeach()

    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${V_GEN}
        COMMAND ${Python3_EXECUTABLE} -m tmrv
        ${SOURCES} 
        -o ${OUTDIR}

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





