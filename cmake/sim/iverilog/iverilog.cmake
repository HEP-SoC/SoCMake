include_guard(GLOBAL)

function(iverilog IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
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

    get_ip_include_directories(INC_DIRS ${IP_LIB})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -I ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    set(EXEC "${OUTDIR}/${IP_LIB}_iv")
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${EXEC} ${STAMP_FILE}
        COMMAND iverilog
        ${SOURCES}
        ${ARG_INCDIRS}
        ${CMP_DEFS_ARG}
        -o ${EXEC}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running iverilog on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${EXEC} ${STAMP_FILE} ${IP_LIB}
        )

    add_custom_target(
        run_${IP_LIB}_iv
        COMMAND exec ${EXEC}
        BYPRODUCTS "${OUTDIR}/test1.vcd"
        DEPENDS ${EXEC} ${STAMP_FILE} ${SOURCES} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        )

    # add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()

