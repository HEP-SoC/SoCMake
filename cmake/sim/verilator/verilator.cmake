function(verilator IP_LIB)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS;MAIN;NO_RUN_TARGET;SED_WOR")
    set(ONE_PARAM_ARGS "EXEC_TARGET;PREFIX;TOP_MODULE;THREADS;TRACE_THREADS;DIRECTORY;RUN_TARGET_NAME")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS;OPT_SLOW;OPT_FAST;OPT_GLOBAL;RUN_ARGS")

    cmake_parse_arguments(ARG
        "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    # Check verilator is installed
    find_package(verilator REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
    set(VERILATOR_INCLUDE_DIR ${VERILATOR_ROOT}/include)

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Check and process the arguments
    if(NOT ARG_DIRECTORY)
        set(DIRECTORY "${BINARY_DIR}/${IP_LIB}_verilator")
    else()
        set(DIRECTORY ${ARG_DIRECTORY})
    endif()

    if(ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_PREFIX)
        set(PREFIX ${ARG_PREFIX})
    else()
        set(PREFIX V${ARG_TOP_MODULE})
    endif()

    if(ARG_RUN_ARGS)
        set(__ARG_RUN_ARGS ${ARG_RUN_ARGS})
        unset(ARG_RUN_ARGS)
    endif() 

    if(ARG_NO_RUN_TARGET)
        set(__ARG_NO_RUN_TARGET ${ARG_NO_RUN_TARGET})
        unset(ARG_NO_RUN_TARGET)
    endif()

    if (ARG_TRACE AND ARG_TRACE_FST)
        message(FATAL_ERROR "Cannot have both TRACE and TRACE_FST")
    elseif(ARG_TRACE)
        set(TRACE_ARG ${ARG_TRACE})
    elseif(ARG_TRACE_FST)
        set(TRACE_ARG ${ARG_TRACE_FST})
    endif()

    if(ARG_COVERAGE)
        set(COVERAGE_ARG ${ARG_COVERAGE})
    endif()
    if(ARG_SYSTEMC)
        set(SYSTEMC_ARG ${ARG_SYSTEMC})
    endif()
    if(ARG_TRACE_STRUCTS)
        set(TRACE_STRUCTS_ARG ${ARG_TRACE_STRUCTS})
    endif()
    if(ARG_THREADS)
        set(THREADS_ARG ${ARG_PREFIX})
    endif()
    if(ARG_TRACE_THREADS)
        set(TRACE_THREADS_ARG ${ARG_PREFIX})
    endif()

    # Retrieve the targeted IP properties
    get_ip_include_directories(INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG)

    ## TODO deprecate
    get_ip_property(VERILATOR_ARGS ${IP_LIB} VERILATOR_ARGS)
    list(APPEND ARG_VERILATOR_ARGS ${VERILATOR_ARGS})
    ##

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)
    foreach(def ${COMP_DEFS})
        list(APPEND ARG_VERILATOR_ARGS -D${def})
    endforeach()

    get_ip_sources(SOURCES ${IP_LIB} VERILATOR_CFG SYSTEMVERILOG_SIM VERILOG_SIM SYSTEMVERILOG VERILOG)

    if(ARG_SED_WOR)
        include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/sed_wor/sed_wor.cmake)
        sed_wor(${IP_LIB} ${BINARY_DIR} "${SOURCES}")
        set(SOURCES ${SED_WOR_SOURCES})
        unset(ARG_SED_WOR)
    endif()

    if(NOT SOURCES)
        message(FATAL_ERROR "Verilate function needs at least one VERILOG or SYSTEMVERILOG source added to the IP")
    endif()
    
    # Create the verilated library of the IP
    set(VERILATED_LIB ${IP_LIB}__vlt)
    add_library(${VERILATED_LIB})
    add_dependencies(${VERILATED_LIB} ${IP_LIB})

    verilate(${VERILATED_LIB}
        ${COVERAGE_ARG}
        ${TRACE_ARG}
        ${SYSTEMC_ARG}
        ${TRACE_STRUCTS_ARG}
        PREFIX ${PREFIX}
        TOP_MODULE ${ARG_TOP_MODULE}
        ${THREADS_ARG}
        ${TRACE_THREADS_ARG}
        DIRECTORY ${DIRECTORY}
        SOURCES ${SOURCES}
        VERILATOR_ARGS ${ARG_VERILATOR_ARGS}
        INCLUDE_DIRS ${INCLUDE_DIRS}
        OPT_SLOW ${ARG_OPT_SLOW}
        OPT_FAST ${ARG_OPT_FAST}
        OPT_GLOBAL ${ARG_OPT_GLOBAL}
    )

    if(ARG_SYSTEMC)
        find_package(SystemCLanguage REQUIRED HINTS ${SYSTEMC_ROOT})
        verilator_link_systemc(${VERILATED_LIB})
    endif()

    set(INC_DIR ${DIRECTORY})
    target_include_directories(${VERILATED_LIB} INTERFACE ${INC_DIR})
    target_include_directories(${VERILATED_LIB} INTERFACE
        "${VERILATOR_INCLUDE_DIR}"
        "${VERILATOR_INCLUDE_DIR}/vltstd")

    # Search for linked libraries that are Shared or Static libraries and link them to the verilated library
    get_ip_links(IPS_LIST ${IP_LIB})
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            target_link_libraries(${VERILATE_TARGET} INTERFACE ${ip})
        endif()
    endforeach()

    string(REPLACE "__" "::" ALIAS_NAME "${VERILATED_LIB}")
    add_library(${ALIAS_NAME} ALIAS ${VERILATED_LIB})

    unset(EXEC_NAME)
    if(ARG_EXEC_TARGET)
        set(EXEC_NAME ${PROJECT_BINARY_DIR}/${ARG_EXEC_TARGET})
        set(__sim_run_cmd ${EXEC_NAME} ${__ARG_RUN_ARGS})
    endif()

    if(EXEC_NAME AND NOT __ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        # Add a custom target to run the generated executable
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND ${__sim_run_cmd}
            DEPENDS ${STAMP_FILE} ${VERILATED_LIB} ${ARG_EXEC_TARGET}
            COMMENT ${DESCRIPTION}
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(SIM_RUN_CMD ${__sim_run_cmd} PARENT_SCOPE)

    # TODO: Remove this if Verilator ever supports "wor"
    if(TARGET ${IP_LIB}_sed_wor)
        add_dependencies(${VERILATED_LIB} ${IP_LIB}_sed_wor)
    endif()
endfunction()
