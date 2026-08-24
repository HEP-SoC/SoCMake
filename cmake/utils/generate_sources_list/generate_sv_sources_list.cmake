include("${CMAKE_CURRENT_LIST_DIR}/../socmake_message.cmake")
#[[[
# Generate a dependency-ordered Verilog/SystemVerilog source list for an IP target, including only instantiated modules.
#
# This function collects all Verilog/SystemVerilog source files associated with the given ~IP_LIB~ target.
# It produces two files containing:
#  * A dependency-ordered list of all Verilog/SystemVerilog source files (rtl_sources.f)
#  * A list of all include files (include_sources.f)
#
# The hierarchy is parsed using `slang` (https://github.com/MikePopoloski/slang), ensuring that only the necessary
# files for the specified top module (if provided) and its dependencies are included.
#
# :param IP_LIB: Name of the IP library target to analyze.
# :type IP_LIB: string
#
# **Keyword Arguments**
# :keyword OUTDIR: (Optional) Output directory for the generated file lists. Defaults to ${CMAKE_BINARY_DIR}/ip_sources
# :type OUTDIR: string
# :keyword TOP_MODULE: (Optional) Name of the top module to use as the root of the hierarchy. Only modules below this point are included. An error is reported if the specified module does not exist.
# :type TOP_MODULE: string
# :keyword SLANG_ARGS: (Optional) Extra arguments to pass directly to slang.
# :type SLANG_ARGS: list
# :keyword FILE_SETS: (Optional) Restrict the collected sources and include directories to the listed file sets; all file sets are used when omitted.
# :type FILE_SETS: list
# :keyword TARGET_NAME_QUALIFIER: (Optional) Qualifier inserted into the generated target name `<IP_LIB>_source_list`, producing `<IP_LIB>_<qualifier>_source_list`.
# :type TARGET_NAME_QUALIFIER: string
#]]
function(generate_sv_sources_list IP_LIB)
    set(options)
    set(oneValueArgs OUTDIR TOP_MODULE TARGET_NAME_QUALIFIER)
    set(multiValueArgs FILE_SETS SLANG_ARGS)

    cmake_parse_arguments(
        ARG
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Find slang executable
    find_program(SLANG_EXECUTABLE slang)
    if(NOT SLANG_EXECUTABLE)
        if(NOT DEFINED ENV{SLANG_EXECUTABLE})
            socmake_message(WARNING "slang executable not found! Please install slang or set SLANG_EXECUTABLE.")
        else()
            socmake_message(STATUS "slang executable found using SLANG_EXECUTABLE env variable: $ENV{SLANG_EXECUTABLE}")
            set(SLANG_EXECUTABLE $ENV{SLANG_EXECUTABLE})
        endif()
    endif()

    # Initialize variables
    set(INCDIR_ARG)
    set(TOP_MODULE_ARG)
    set(USER_SLANG_ARGS)

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    alias_dereference(IP_LIB ${IP_LIB})

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # If a top module is provided, only modules in its hierarchy are included.
    if(ARG_TOP_MODULE)
        list(APPEND TOP_MODULE_ARG --top ${ARG_TOP_MODULE})
    endif()
    # Restrict to the requested file sets, if any; otherwise all file sets are used.
    set(FILE_SETS_ARG)
    if(ARG_FILE_SETS)
        set(FILE_SETS_ARG FILE_SETS ${ARG_FILE_SETS})
    endif()

    # Get the list of RTL sources
    get_ip_sources(RTL_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG ${FILE_SETS_ARG})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG ${FILE_SETS_ARG})
    foreach(_i ${RTL_INCDIRS})
        list(APPEND INCDIR_ARG -I${_i})
    endforeach()

    # Get the list of compile definitions for the IP library
    get_ip_compile_definitions(RTL_COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG ${FILE_SETS_ARG})
    foreach(compdef ${RTL_COMP_DEFS})
        list(APPEND USER_SLANG_ARGS -D${compdef})
    endforeach()

    if(ARG_SLANG_ARGS)
        list(APPEND USER_SLANG_ARGS ${ARG_SLANG_ARGS})
    endif()

    set(RTL_FILE ${OUTDIR}/rtl_sources.f)
    set(INCLUDE_FILE ${OUTDIR}/include_sources.f)
    file(MAKE_DIRECTORY ${OUTDIR})

    set(SLANG_CMD
        ${SLANG_EXECUTABLE}
        --depfile-trim
        --Mmodule
        ${RTL_FILE}
        --Minclude
        ${INCLUDE_FILE}
        ${TOP_MODULE_ARG}
        ${INCDIR_ARG}
        ${USER_SLANG_ARGS}
        ${RTL_SOURCES}
    )

    get_ip_links(DEPENDENT_TARGETS ${IP_LIB})

    add_custom_command(
        OUTPUT ${RTL_FILE} ${INCLUDE_FILE}
        COMMAND ${SLANG_CMD}
        DEPENDS ${DEPENDENT_TARGETS} ${RTL_SOURCES}
        COMMENT "Generating list of the RTL source files in ${OUTDIR}"
        VERBATIM
    )

    set(DESCRIPTION
        "Generate dependency-ordered Verilog/SystemVerilog source list for ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}"
    )

    set(TARGET_NAME ${IP_LIB}_source_list)
    if(ARG_TARGET_NAME_QUALIFIER)
        set(TARGET_NAME ${IP_LIB}_${ARG_TARGET_NAME_QUALIFIER}_source_list)
    endif()

    add_custom_target(
        ${TARGET_NAME}
        DEPENDS ${RTL_FILE} ${INCLUDE_FILE}
        COMMENT ${DESCRIPTION}
        VERBATIM
    )

    set_property(
        TARGET ${TARGET_NAME}
        PROPERTY DESCRIPTION ${DESCRIPTION}
    )
endfunction()
