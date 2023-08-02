function(verilate IP_LIB)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;THREADS;TRACE_THREADS;DIRECTORY")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS;OPT_SLOW;OPT_FAST;OPT_GLOBAL")

    cmake_parse_arguments(ARG "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_DIRECTORY)
        set(DIRECTORY "${BINARY_DIR}/${IP_LIB}_verilate")
    else()
        set(DIRECTORY ${ARG_DIRECTORY})
    endif()

    get_ip_include_directories(INCLUDE_DIRS ${IP_LIB})

    if(ARG_TOP_MODULE)
        set(TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_PREFIX)
        set(PREFIX ${ARG_PREFIX})
    else()
        set(PREFIX V${TOP_MODULE})
    endif()

    get_ip_property(VERILATOR_ARGS ${IP_LIB} VERILATOR_ARGS)
    list(APPEND VERILATOR_ARGS ${ARG_VERILATOR_ARGS})

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    if(NOT SOURCES)
        message(FATAL_ERROR "Verilate function needs at least one VERILOG or SYSTEMVERILOG source added to the IP")
    endif()

    if(TRACE_STRUCTS)
        list(APPEND VERILATOR_ARGS --trace-structs)
    endif()

    if(ARG_SYSTEMC)
        set(SYSTEMC TRUE)
    endif()

    set(PASS_MULTIPARAM SOURCES VERILATOR_ARGS INCLUDE_DIRS SYSTEMC) # TODO Pass more stuff from top
    set(PASS_ONEPARAM DIRECTORY TOP_MODULE PREFIX)
    set(PASS_OPTIONS ARG_TRACE_STRUCTS)

    foreach(param ${PASS_MULTIPARAM})
        string(REPLACE ";" "|" ${param} "${${param}}")
    endforeach()

    foreach(param ${PASS_MULTIPARAM} ${PASS_OPTIONS} ${PASS_ONEPARAM})
        if(${param})
            list(APPEND EXT_PRJ_ARGS "-DVERILATE_${param}=${${param}}")
            list(APPEND ARGUMENTS_LIST ${param})
        endif()
    endforeach()
    string(REPLACE ";" "|" ARGUMENTS_LIST "${ARGUMENTS_LIST}")

    if(NOT VERILATOR_HOME)
        find_package(verilator REQUIRED
            HINTS ${VERISC_HOME}/open/* $ENV{VERISC_HOME}/open/*
            )
        set(VERILATOR_HOME "${verilator_DIR}/../../")
    endif()

    if(NOT SYSTEMC_HOME)
        find_package(SystemCLanguage REQUIRED
            HINTS ${VERISC_HOME}/open/* $ENV{VERISC_HOME}/open/*
            )
        set(SYSTEMC_HOME "${SystemCLanguage_DIR}/../../../")
    endif()
    
    if(CMAKE_CXX_STANDARD)
        set(ARG_CMAKE_CXX_STANDARD "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    set(VERILATE_TARGET ${IP_LIB}_verilate)
    include(ExternalProject)
    ExternalProject_Add(${VERILATE_TARGET}
        DOWNLOAD_COMMAND ""
        SOURCE_DIR "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/verilator"
        PREFIX ${DIRECTORY}
        BINARY_DIR ${DIRECTORY}
        LIST_SEPARATOR |
        BUILD_ALWAYS 1

        CMAKE_ARGS
            ${ARG_CMAKE_CXX_STANDARD}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}

            -DTARGET=${TOP_MODULE} # USE TOP_MODULE MAYBE???? TODO
            -DARGUMENTS_LIST=${ARGUMENTS_LIST}
            ${EXT_PRJ_ARGS}
            -DVERILATOR_ROOT=${VERILATOR_HOME}
            -DSYSTEMC_ROOT=${SYSTEMC_HOME}

        INSTALL_COMMAND ""
        DEPENDS ${IP_LIB}
        EXCLUDE_FROM_ALL 1
        ) 

    set(VLT_STATIC_LIB "${DIRECTORY}/lib${TOP_MODULE}.a")
    set(INC_DIR ${DIRECTORY})

    set(VERILATED_LIB ${IP_LIB}__vlt)
    add_library(${VERILATED_LIB} STATIC IMPORTED)
    add_dependencies(${VERILATED_LIB} ${VERILATE_TARGET})
    set_target_properties(${VERILATED_LIB} PROPERTIES IMPORTED_LOCATION ${VLT_STATIC_LIB})

    target_include_directories(${VERILATED_LIB} INTERFACE ${INC_DIR})
    target_include_directories(${VERILATED_LIB} INTERFACE
        "${VERILATOR_HOME}/include"
        "${VERILATOR_HOME}/include/vltstd")

    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)

    target_link_libraries(${VERILATED_LIB} INTERFACE -pthread)

    get_target_property(TYPE ${VERILATED_LIB} TYPE)

    string(REPLACE "__" "::" ALIAS_NAME "${VERILATED_LIB}")
    add_library(${ALIAS_NAME} ALIAS ${VERILATED_LIB})
endfunction()
