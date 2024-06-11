
function(tmake IP_LIB)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS;MAIN")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;THREADS;TRACE_THREADS;DIRECTORY;EXECUTABLE_NAME")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS;OPT_SLOW;OPT_FAST;OPT_GLOBAL")

    cmake_parse_arguments(ARG
        "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    # get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # if(NOT ARG_DIRECTORY)
    #     set(DIRECTORY "${BINARY_DIR}/${IP_LIB}_verilate")
    # else()
    #     set(DIRECTORY ${ARG_DIRECTORY})
    # endif()

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    # set(INCLUDE_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    get_ip_property(VERILATOR_ARGS ${IP_LIB} VERILATOR_ARGS)
    list(APPEND ARG_VERILATOR_ARGS ${VERILATOR_ARGS})

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND ARG_VERILATOR_ARGS -D${def})
    endforeach()

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    # get_ip_sources(CFG_FILE ${IP_LIB} VERILATOR_CFG)
    # list(PREPEND SOURCES ${CFG_FILE})

    if(NOT SOURCES)
        message(FATAL_ERROR "Verilate function needs at least one VERILOG or SYSTEMVERILOG source added to the IP")
    endif()

    if(ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    endfunction()
