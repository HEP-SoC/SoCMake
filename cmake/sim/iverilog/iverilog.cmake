include_guard(GLOBAL)

function(iverilog IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;EXECUTABLE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INC_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -I ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    if(NOT ARG_EXECUTABLE)
        set(ARG_EXECUTABLE "${OUTDIR}/${IP_LIB}_iv")
    endif()
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${ARG_EXECUTABLE} ${STAMP_FILE}
        COMMAND iverilog
        ${ARG_INCDIRS}
        ${CMP_DEFS_ARG}
        -o ${ARG_EXECUTABLE}
        ${SOURCES}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running iverilog on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${ARG_EXECUTABLE} ${STAMP_FILE} ${IP_LIB}
        )

    add_custom_target(
        run_${IP_LIB}_iv
        COMMAND exec ${ARG_EXECUTABLE}
        DEPENDS ${ARG_EXECUTABLE} ${STAMP_FILE} ${SOURCES} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        )

    # add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()

