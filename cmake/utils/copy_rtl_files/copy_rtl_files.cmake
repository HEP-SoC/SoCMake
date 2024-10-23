#[[[
# This function copies the RTL sources of an IP to a given location.
#
# This function gets an IP_LIB target and get its RTL source files (exluding SIM/TB/FPGA files) and include directories and copy
# them to a default or given location. The output location contains a file listing all the sources, an include directory containing
# all the include files and the source files with a preserved hierarchy folder. It uses the vhier tool to parse and build the library
# hierachy and copy only the files instantiated in the hierarchy.
# vhier is part of a set of tools:
# https://github.com/gitpan/Verilog-Perl
# https://metacpan.org/pod/vhier
#
# :param IP_LIB: IP library to get RTL sources from.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword SYNTHESIS: Define SYNTHESIS, and ignore text between "ambit", "pragma", "synopsys" or "synthesis" translate_off and translate_on meta comments.
# :type SYNTHESIS: string
# :keyword OUTDIR: Change the default copy location ${CMAKE_BINARY_DIR}/ip_sources to OUTDIR.
# :type OUTDIR: string
# :keyword TOP_MODULE: Start the report at the specified module name, ignoring all modules that are not the one specified with --top-module or below, and report an error if the --top-module specified does not exist.
# :type TOP_MODULE: string
# :keyword SKIPLIST_FILE: Given file contains a list of regular expressions, one per line. If a module name in the design hierarchy matches one of these expressions, skip showing that module and any sub-hierarchy.
# :type SKIPLIST_FILE: string
#]]
function(copy_rtl_files IP_LIB)
    cmake_parse_arguments(ARG "SYNTHESIS" "OUTDIR;TOP_MODULE;SKIPLIST_FILE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Check if a top module is provided. In this case only the modules in its hierarchy are kept
    if(ARG_TOP_MODULE)
        set(TOP_MODULE_ARG --top-module ${ARG_TOP_MODULE})
    endif()

    if(ARG_SKIPLIST_FILE)
        set(SKIPLIST_ARG --skiplist ${ARG_SKIPLIST_FILE})
    endif()

    if(ARG_SYNTHESIS)
        set(SYNTHESIS_ARG --synthesis)
    endif()

    # Get the list of RTL sources
    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    foreach(_i ${RTL_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} --include ${_i})
    endforeach()

    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/copy_rtl_files.py
        ${TOP_MODULE_ARG} ${SKIPLIST_ARG} ${SYNTHESIS_ARG}
        --deps_dir ${FETCHCONTENT_BASE_DIR}
        ${INCDIR_ARG}
        --outdir ${OUTDIR}
        ${RTL_SOURCES}
    )

    # # Call the Python script with the output directory and the RTL files
    # set(STAMP_FILE "${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    # add_custom_command(
    #     OUTPUT ${STAMP_FILE}
    #     COMMAND ${__CMD}
    #     COMMAND /bin/sh -c date > ${STAMP_FILE}
    #     COMMENT "Copying RTL files to ${OUTDIR}"
    #     VERBATIM
    # )

    # Create a target to run the custom command
    add_custom_target(
        ${IP_LIB}_copy_rtl
        ALL # This forces the target to be run every time as outputs are not known in advance
        COMMAND ${__CMD}
        COMMENT "Copying RTL files to ${OUTDIR}"
        DEPENDS ${IP_LIB} ${STAMP_FILE}
        VERBATIM
    )

endfunction()
