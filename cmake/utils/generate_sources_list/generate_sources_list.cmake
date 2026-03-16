#[[[
# Generates a filtered and organized list of RTL (Register Transfer Level) source files for a specified IP library target.
#
# This function collects all relevant RTL source files (excluding simulation, testbench, and FPGA-specific files) associated
# with the given ~IP_LIB~ target. It produces a file containing:
#  * All source files required for synthesis, preserving their directory hierarchy.
#  * All include directories and files needed for compilation.
#  * Only the files instantiated in the design hierarchy, as determined by the `slang` tool.
#
# The hierarchy is parsed using `slang` (https://github.com/MikePopoloski/slang), ensuring that only the necessary
# files for the specified top module (if provided) and its dependencies are included.
#
# :param IP_LIB: Name of the IP library target to analyze.
# :type IP_LIB: string
#
# **Keyword Arguments**
# :keyword SYNTHESIS: (Optional) If specified, defines SYNTHESIS macro while parsing the HDL sources.
# :type SYNTHESIS: boolean
# :keyword OUTDIR: (Optional) Output directory for the copied RTL sources. Defaults to ${CMAKE_BINARY_DIR}/ip_sources
# :type OUTDIR: string
# :keyword TOP_MODULE: (Optional) Name of the top module to use as the root of the hierarchy. Only modules below this point are included. An error is reported if the specified module does not exist.
# :type TOP_MODULE: string
#]]
function(generate_sources_list IP_LIB)
    cmake_parse_arguments(ARG "SYNTHESIS" "OUTDIR;TOP_MODULE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Initialize variables
    set(INCDIR_ARG "")
    set(TOP_MODULE_ARG "")
    set(SYNTHESIS_ARG "")

    # Check if the Python script exists
    if(NOT EXISTS "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/generate_sources_list.py")
      message(FATAL_ERROR "generate_sources_list.py not found!")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # If a top module is provided, only modules in its hierarchy are included.
    if(ARG_TOP_MODULE)
        set(TOP_MODULE_ARG --top-module ${ARG_TOP_MODULE})
    endif()

    # Get the list of RTL sources
    get_ip_sources(RTL_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG)
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    foreach(_i ${RTL_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} --include ${_i})
    endforeach()

    if(ARG_SYNTHESIS)
        set(SYNTHESIS_ARG --synthesis)
    endif()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/generate_sources_list.py
        ${TOP_MODULE_ARG} ${SYNTHESIS_ARG}
        ${INCDIR_ARG}
        --outdir ${OUTDIR}
        ${RTL_SOURCES}
    )

    # Create a target to run the custom command
    add_custom_target(
        ${IP_LIB}_source_list
        ALL # This forces the target to be run every time as outputs are not known in advance
        COMMAND ${__CMD}
        COMMENT "Generating list of the RTL source files in ${OUTDIR}"
        DEPENDS ${IP_LIB}
        VERBATIM
    )

endfunction()
