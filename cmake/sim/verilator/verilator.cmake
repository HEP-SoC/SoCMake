#[[[ @module verilator
#]]

#[[[
# Create a target for invoking verilator (compilation, elaboration, and simulation) on IP_LIB.
#
# It will create a target **run_<IP_LIB>_verilator** that will compile, elaborate, and simulate the IP_LIB design.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword COVERAGE: Enable code coverage during compilation and simulation.
# :type COVERAGE: bool
# :keyword TRACE: Enable waveform tracing.
# :type TRACE: bool
# :keyword TRACE_FST: Enable FST waveform tracing format.
# :type TRACE_FST: bool
# :keyword SYSTEMC: Enable SystemC support.
# :type SYSTEMC: bool
# :keyword TRACE_STRUCTS: Enable tracing of SystemVerilog structs.
# :type TRACE_STRUCTS: bool
# :keyword MAIN: Generate a top-level C++ ``main()`` that parses arguments but drives no inputs. Sufficient for top-level SystemVerilog designs with no inputs. Also creates a runnable executable target.
# :type MAIN: bool
# :keyword TIMING: Enable timing support in simulation.
# :type TIMING: bool
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword PREFIX: Prefix name used for generated output files and targets.
# :type PREFIX: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword THREADS: Number of threads to be used during compilation or simulation.
# :type THREADS: int
# :keyword DIRECTORY: Output directory for generated build and simulation files.
# :type DIRECTORY: string
# :keyword EXECUTABLE_NAME: Replace the default name of the generated executable target.
# :type EXECUTABLE_NAME: string
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword VERILATOR_ARGS: Extra arguments to be passed to the Verilator invocation.
# :type VERILATOR_ARGS: string
# :keyword OPT_SLOW: Enable slow but optimized compilation mode.
# :type OPT_SLOW: bool
# :keyword OPT_FAST: Enable fast compilation optimization mode.
# :type OPT_FAST: bool
# :keyword OPT_GLOBAL: Enable global optimization mode.
# :type OPT_GLOBAL: bool
# :keyword RUN_ARGS: Extra arguments to be passed to the simulation executable.
# :type RUN_ARGS: string
# :keyword FILE_SETS: Specify list of file sets to retrieve the sources from.
# :type FILE_SETS: list[string]
#]]
function(verilator IP_LIB)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS;MAIN;TIMING;NO_RUN_TARGET")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;THREADS;DIRECTORY;EXECUTABLE_NAME;RUN_TARGET_NAME")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS;OPT_SLOW;OPT_FAST;OPT_GLOBAL;RUN_ARGS;FILE_SETS")

    cmake_parse_arguments(ARG
        "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Optimization to not do topological sort of linked IPs on get_ip_...() calls
    flatten_graph_and_disallow_flattening(${IP_LIB})

    enable_language(CXX C)      # We need to enable CXX and C for Verilator

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_DIRECTORY)
        set(VERILATE_PRJ_PREFIX_DIR "${BINARY_DIR}/${IP_LIB}_verilator")
    else()
        set(VERILATE_PRJ_PREFIX_DIR "${ARG_DIRECTORY}")
    endif()
    set(DIRECTORY "${VERILATE_PRJ_PREFIX_DIR}/verilate")

    if(ARG_FILE_SETS)
        list(REMOVE_ITEM MULTI_PARAM_ARGS "FILE_SETS")
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    ##################################
    ## Find verilator installation ###
    ##################################
    if(NOT VERILATOR_HOME)
        # Ensure CMP0144 is set before find_package to get rid of warning
        cmake_policy(PUSH)
        cmake_policy(SET CMP0144 NEW)
        find_package(verilator REQUIRED)
        set(VERILATOR_HOME "${verilator_DIR}/../../")
        cmake_policy(POP)
    endif()

    find_file(_VERILATED_H verilated.h REQUIRED
        HINTS ${VERILATOR_HOME}/include ${verilator_DIR}/include
        )
    get_filename_component(VERILATOR_INCLUDE_DIR ${_VERILATED_H} DIRECTORY)

    set(VERILATOR_ROOT ${VERILATOR_INCLUDE_DIR}/../)
    ##################################

    get_ip_include_directories(INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})

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

    ## TODO deprecate
    get_ip_property(VERILATOR_ARGS ${IP_LIB} VERILATOR_ARGS)
    list(APPEND ARG_VERILATOR_ARGS ${VERILATOR_ARGS})
    ##

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
    foreach(def ${COMP_DEFS})
        list(APPEND ARG_VERILATOR_ARGS -D${def})
    endforeach()

    get_ip_sources(SOURCES ${IP_LIB} VLT VERILATOR_CFG SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
    if(NOT SOURCES)
        message(FATAL_ERROR "Verilate function needs at least one VERILOG or SYSTEMVERILOG source added to the IP")
    endif()

    unset(EXECUTABLE_PATH)
    if(ARG_MAIN)
        list(APPEND ARG_VERILATOR_ARGS --main)
        if(NOT ARG_EXECUTABLE_NAME)
            set(ARG_EXECUTABLE_NAME ${IP_LIB}_verilator_exec)
        endif()
        set(EXECUTABLE_PATH ${BINARY_DIR}/${ARG_EXECUTABLE_NAME})
        unset(ARG_MAIN)
    endif()

    # Additional libraries and options that should be forwarded to the executable that links to the verilated library (like libz when TRACE_FST is used, ...)
    unset(interface_compile_options)
    unset(interface_link_libraries)

    if(ARG_TIMING)
        list(APPEND ARG_VERILATOR_ARGS --timing)
        list(APPEND interface_compile_options -fcoroutines)
        unset(ARG_TIMING)
    endif()

    if(ARG_TRACE_FST)
        list(APPEND interface_link_libraries z)
    endif()

    if(ARG_RUN_ARGS)
        set(__ARG_RUN_ARGS ${ARG_RUN_ARGS})
        unset(ARG_RUN_ARGS)
    endif()

    if(ARG_NO_RUN_TARGET)
        set(__ARG_NO_RUN_TARGET ${ARG_NO_RUN_TARGET})
        unset(ARG_NO_RUN_TARGET)
    endif()

    set(PASS_ADDITIONAL_MULTIPARAM SOURCES INCLUDE_DIRS) # Additional parameters to pass
    set(PASS_ADDITIONAL_ONEPARAM DIRECTORY PREFIX)
    set(PASS_ADDITIONAL_OPTIONS)

    foreach(param ${PASS_ADDITIONAL_MULTIPARAM})
        if(${param})
            string(REPLACE ";" "|" ${param} "${${param}}")
        endif()
    endforeach()
    foreach(param ${MULTI_PARAM_ARGS})
        if(ARG_${param})
            string(REPLACE ";" "|" ARG_${param} "${ARG_${param}}")
        endif()
    endforeach()

    foreach(param ${MULTI_PARAM_ARGS} ${OPTIONS} ${ONE_PARAM_ARGS})
        if(ARG_${param})
            list(APPEND EXT_PRJ_ARGS "-DVERILATE_${param}=${ARG_${param}}")
            list(APPEND ARGUMENTS_LIST ${param})
        endif()
    endforeach()
    foreach(param ${PASS_ADDITIONAL_MULTIPARAM} ${PASS_ADDITIONAL_ONEPARAM} ${PASS_ADDITIONAL_OPTIONS})
        if(${param})
            list(APPEND EXT_PRJ_ARGS "-DVERILATE_${param}=${${param}}")
            list(APPEND ARGUMENTS_LIST ${param})
        endif()
    endforeach()
    string(REPLACE ";" "|" ARGUMENTS_LIST "${ARGUMENTS_LIST}")

    if(ARG_SYSTEMC)
        if(NOT SYSTEMC_HOME)
            find_package(SystemCLanguage REQUIRED)
            set(SYSTEMC_HOME "${SystemCLanguage_DIR}/../../../")
        endif()
    endif()

    if(CMAKE_CXX_STANDARD)
        set(ARG_CMAKE_CXX_STANDARD "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    ##################################
    ## Prepare help message ##########
    ##################################
    set(DESCRIPTION "Compiling ${IP_LIB} with verilator as static library")

    set(VLT_STATIC_LIB "${VERILATE_PRJ_PREFIX_DIR}/lib${ARG_TOP_MODULE}.a")

    set(VERILATE_TARGET ${IP_LIB}_verilate)
    if(NOT TARGET ${IP_LIB}_verilate)
        include(ExternalProject)
        ExternalProject_Add(${VERILATE_TARGET}
            DOWNLOAD_COMMAND ""
            SOURCE_DIR "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/verilator"
            PREFIX ${VERILATE_PRJ_PREFIX_DIR}
            BINARY_DIR ${VERILATE_PRJ_PREFIX_DIR}
            LIST_SEPARATOR |
            BUILD_ALWAYS 1
            BUILD_BYPRODUCTS ${VLT_STATIC_LIB}


            CMAKE_ARGS
                ${ARG_CMAKE_CXX_STANDARD}
                -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${BINARY_DIR}

                -DTARGET=${ARG_TOP_MODULE}
                -DARGUMENTS_LIST=${ARGUMENTS_LIST}
                ${EXT_PRJ_ARGS}
                -DVERILATOR_ROOT=${VERILATOR_ROOT}
                -DSYSTEMC_ROOT=${SYSTEMC_HOME}
            # VERILATOR_ROOT env variable is required for some older versions of verilator
            # For the configuration phase, this is set in the verilator/CMakeLists.txt file
            # For the build phase, this is the simplest (only?) solution
            BUILD_COMMAND ${CMAKE_COMMAND} -E env VERILATOR_ROOT=${VERILATOR_ROOT} make -j${CMAKE_BUILD_PARALLEL_LEVEL}
            INSTALL_COMMAND ""
            DEPENDS ${IP_LIB}
            EXCLUDE_FROM_ALL 1

            # For Ninja so it prints status live and not delayed
            USES_TERMINAL_CONFIGURE TRUE
            USES_TERMINAL_BUILD TRUE

            COMMENT ${DESCRIPTION}
            )
        set_property(TARGET ${VERILATE_TARGET} PROPERTY DESCRIPTION ${DESCRIPTION})

        file(MAKE_DIRECTORY ${DIRECTORY}) # target_include_directories would fail otherwise

        ################################################################
        ## Create the IMPORTED library from the static verilated library
        ################################################################

        set(THREADS_PREFER_PTHREAD_FLAG ON)
        find_package(Threads REQUIRED)

        set(VERILATED_LIB ${IP_LIB}__vlt)
        add_library(${VERILATED_LIB} STATIC IMPORTED)
        set_target_properties(${VERILATED_LIB} PROPERTIES IMPORTED_GLOBAL TRUE)
        add_dependencies(${VERILATED_LIB} ${VERILATE_TARGET})
        set_target_properties(${VERILATED_LIB} PROPERTIES IMPORTED_LOCATION ${VLT_STATIC_LIB})

        target_include_directories(${VERILATED_LIB} INTERFACE
            "${DIRECTORY}"
            "${VERILATOR_INCLUDE_DIR}"
            "${VERILATOR_INCLUDE_DIR}/vltstd")
        target_compile_options(${VERILATED_LIB} INTERFACE
            ${interface_compile_options}
        )
        target_link_libraries(${VERILATED_LIB} INTERFACE
            ${interface_link_libraries}
            -pthread
        )

        # Search for linked libraries that are Shared or Static libraries and link them to the verilated library
        get_ip_links(IPS_LIST ${IP_LIB})
        foreach(ip ${IPS_LIST})
            get_target_property(ip_type ${ip} TYPE)
            if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
                target_link_libraries(${VERILATED_LIB} INTERFACE ${ip})
            endif()
        endforeach()

        string(REPLACE "__" "::" ALIAS_NAME "${VERILATED_LIB}")
        add_library(${ALIAS_NAME} ALIAS ${VERILATED_LIB})
    endif()

    if(EXECUTABLE_PATH AND NOT TARGET ${ARG_EXECUTABLE_NAME})
        set(GENERATED_MAIN "${DIRECTORY}/${PREFIX}__main.cpp")
        set_property(SOURCE ${GENERATED_MAIN} PROPERTY GENERATED TRUE)
        add_executable(${ARG_EXECUTABLE_NAME}
            ${GENERATED_MAIN}
            )
        target_link_libraries(${ARG_EXECUTABLE_NAME} PRIVATE
            ${VERILATED_LIB}
            )
        add_dependencies(${ARG_EXECUTABLE_NAME} ${VERILATE_TARGET})
    endif()

    ## Files to be deleted on make clean
    set_property(
        TARGET ${VERILATE_TARGET}
        APPEND PROPERTY ADDITIONAL_CLEAN_FILES
            ${DIRECTORY}
            ${EXECUTABLE_PATH}
            ${VLT_STATIC_LIB}
    )

    set(__sim_run_cmd ${EXECUTABLE_PATH} ${__ARG_RUN_ARGS})
    if(EXECUTABLE_PATH AND NOT __ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        # Add a custom target to run the generated executable
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND ${__sim_run_cmd}
            DEPENDS ${EXECUTABLE_PATH} ${STAMP_FILE} ${VERILATE_TARGET}
            COMMENT ${DESCRIPTION}
            USES_TERMINAL
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(SOCMAKE_SIM_RUN_CMD ${__sim_run_cmd} PARENT_SCOPE)
    set(SOCMAKE_COMPILE_TARGET ${VERILATE_TARGET} PARENT_SCOPE)
    set(SOCMAKE_ELABORATE_TARGET ${ARG_EXECUTABLE_NAME} PARENT_SCOPE)
    if(NOT ARG_NO_RUN_TARGET)
        set(SOCMAKE_RUN_TARGET ${ARG_RUN_TARGET_NAME} PARENT_SCOPE)
    else()
        unset(SOCMAKE_RUN_TARGET PARENT_SCOPE)
    endif()

    # Allow again topological sort outside the function
    socmake_allow_topological_sort(ON)
endfunction()

#[[[
# This macro is used to configure the C and CXX compiler to the one used by the tool.
# In this specific case, it won't change anything for the compiler use but will add some useful information to IP_LIB.
#
# The only supported library by this function is DPI-C, it can be used as done in the following example :
# 
# .. code-block:: cmake
#
#    verilator_configure_cxx(LIBRARIES DPI-C)
#
# **Keyword Arguments**
#
# :keyword LIBRARIES: Libraries that needs to be added.
# :type LIBRARIES: list[string]
#]]
macro(verilator_configure_cxx)
    cmake_parse_arguments(ARG "" "" "LIBRARIES" ${ARGN})
    if(ARG_LIBRARIES)
        verilator_add_cxx_libs(${ARGV})
    endif()
endmacro()

#[[[
# This function is called by the ``verilator_configure_cxx`` macro, you shouldn't use it directly.
#
# It will add the needed information to IP_LIB and add some flags for the compilation and linking.
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bitness.
# :type 32BIT: bool
# :keyword LIBRARIES: libraries that needs to be added, possible choice are DPI-C only for now.
# :type LIBRARIES: list[string]
#]]
function(verilator_add_cxx_libs)
    cmake_parse_arguments(ARG "" "" "LIBRARIES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries DPI-C)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            message(FATAL_ERROR "Verilator does not support library: ${lib}")
        endif()
    endforeach()

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(verilator_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS verilator_dpi-c)
    endif()

endfunction()
