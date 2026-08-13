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
# :keyword TARGET_NAME_SUFFIX: (Optional) Suffix appended to the generated ``<IP_LIB>_source_list`` target name, so multiple calls for the same IP_LIB (e.g. with different OUTDIR/FILE_SETS) don't collide.
# :type TARGET_NAME_SUFFIX: string
# :keyword SPLIT_FILE_SETS: (Optional) Subset of the file sets already selected by FILE_SETS (or of all file sets, if FILE_SETS is omitted) to carve out into a second pair of output files (``rtl_sources_split.f``, ``include_sources_split.f``) instead of the normal ones. Slang's input is unaffected by this keyword — it always sees exactly what FILE_SETS (or its absence) already selects; only how the two output lists are divided afterward changes. This lets a single slang invocation produce output for two destination folders (e.g. everything vs. one technology-specific file set) without the redefinition-clash risk of feeding slang more file sets than it needs, and without a second, redundant elaboration.
# :type SPLIT_FILE_SETS: list
#]]
function(generate_sv_sources_list IP_LIB)
    set(options)
    set(oneValueArgs OUTDIR TOP_MODULE SLANG_ARGS TARGET_NAME_SUFFIX)
    set(multiValueArgs FILE_SETS SPLIT_FILE_SETS)

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

    # SPLIT_FILE_SETS must name a subset of whatever FILE_SETS already resolves to: it never changes what's fed to
    # slang, only how the two output lists are divided afterward.
    if(ARG_SPLIT_FILE_SETS AND ARG_FILE_SETS)
        foreach(_split_fs ${ARG_SPLIT_FILE_SETS})
            if(NOT _split_fs IN_LIST ARG_FILE_SETS)
                socmake_message(FATAL_ERROR
                    "${CMAKE_CURRENT_FUNCTION}: SPLIT_FILE_SETS entry '${_split_fs}' is not part of FILE_SETS '${ARG_FILE_SETS}'"
                )
            endif()
        endforeach()
    endif()

    # Get the list of RTL sources
    get_ip_sources(RTL_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG ${FILE_SETS_ARG})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG ${FILE_SETS_ARG})
    foreach(_i ${RTL_INCDIRS})
        list(APPEND INCDIR_ARG -I${_i})
    endforeach()

    if(ARG_SLANG_ARGS)
        list(APPEND USER_SLANG_ARGS ${ARG_SLANG_ARGS})
    endif()

    set(RTL_FILE ${OUTDIR}/rtl_sources.f)
    set(INCLUDE_FILE ${OUTDIR}/include_sources.f)
    file(MAKE_DIRECTORY ${OUTDIR})

    # When SPLIT_FILE_SETS is used, slang writes its raw, dependency-ordered output to intermediate files; a classify
    # pass afterward divides that output into ${RTL_FILE}/${INCLUDE_FILE} (everything else) and
    # ${RTL_FILE_SPLIT}/${INCLUDE_FILE_SPLIT} (files belonging to SPLIT_FILE_SETS), preserving slang's ordering
    # within each bucket. Without SPLIT_FILE_SETS, slang writes straight to the final files, exactly as before.
    if(ARG_SPLIT_FILE_SETS)
        set(RTL_FILE_SPLIT ${OUTDIR}/rtl_sources_split.f)
        set(INCLUDE_FILE_SPLIT ${OUTDIR}/include_sources_split.f)
        set(RAW_RTL_FILE ${OUTDIR}/.raw_rtl_sources.f)
        set(RAW_INCLUDE_FILE ${OUTDIR}/.raw_include_sources.f)
    else()
        set(RAW_RTL_FILE ${RTL_FILE})
        set(RAW_INCLUDE_FILE ${INCLUDE_FILE})
    endif()

    set(SLANG_CMD
        ${SLANG_EXECUTABLE}
        --depfile-trim
        --Mmodule
        ${RAW_RTL_FILE}
        --Minclude
        ${RAW_INCLUDE_FILE}
        ${TOP_MODULE_ARG}
        ${INCDIR_ARG}
        ${USER_SLANG_ARGS}
        ${RTL_SOURCES}
    )

    get_ip_links(DEPENDENT_TARGETS ${IP_LIB})

    # WORKING_DIRECTORY is pinned explicitly (matching add_custom_command's own default) rather than left implicit,
    # because the classify step below needs to know, unambiguously, the directory slang's relative depfile paths are
    # relative to.
    set(COMMAND_WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    set(CUSTOM_COMMAND_OUTPUTS ${RTL_FILE} ${INCLUDE_FILE})
    set(CUSTOM_COMMAND_COMMANDS COMMAND ${SLANG_CMD})

    if(ARG_SPLIT_FILE_SETS)
        # Membership lists used purely to classify slang's already-correctly-resolved output afterward; they never
        # change what slang itself was given (RTL_SOURCES/RTL_INCDIRS above, built from FILE_SETS_ARG only).
        get_ip_sources(SPLIT_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG FILE_SETS ${ARG_SPLIT_FILE_SETS})
        get_ip_sources(SPLIT_HEADERS ${IP_LIB} SYSTEMVERILOG HEADERS FILE_SETS ${ARG_SPLIT_FILE_SETS})

        # Written to files (rather than passed as -D command-line arguments) to sidestep command-line length limits
        # on IPs with many split-out sources.
        set(SPLIT_SOURCES_ALLOWLIST ${OUTDIR}/.split_sources_allowlist.f)
        set(SPLIT_HEADERS_ALLOWLIST ${OUTDIR}/.split_headers_allowlist.f)
        string(REPLACE ";" "\n" _split_sources_lines "${SPLIT_SOURCES}")
        string(REPLACE ";" "\n" _split_headers_lines "${SPLIT_HEADERS}")
        file(WRITE ${SPLIT_SOURCES_ALLOWLIST} "${_split_sources_lines}\n")
        file(WRITE ${SPLIT_HEADERS_ALLOWLIST} "${_split_headers_lines}\n")

        set(CLASSIFY_SCRIPT ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/classify_sources_list.cmake)

        list(APPEND CUSTOM_COMMAND_OUTPUTS ${RTL_FILE_SPLIT} ${INCLUDE_FILE_SPLIT})
        list(APPEND CUSTOM_COMMAND_COMMANDS
            COMMAND ${CMAKE_COMMAND}
                -DRAW_FILE=${RAW_RTL_FILE}
                -DALLOWLIST_FILE=${SPLIT_SOURCES_ALLOWLIST}
                -DBASE_DIR=${COMMAND_WORKING_DIRECTORY}
                -DMAIN_OUT=${RTL_FILE}
                -DSPLIT_OUT=${RTL_FILE_SPLIT}
                -P ${CLASSIFY_SCRIPT}
            COMMAND ${CMAKE_COMMAND}
                -DRAW_FILE=${RAW_INCLUDE_FILE}
                -DALLOWLIST_FILE=${SPLIT_HEADERS_ALLOWLIST}
                -DBASE_DIR=${COMMAND_WORKING_DIRECTORY}
                -DMAIN_OUT=${INCLUDE_FILE}
                -DSPLIT_OUT=${INCLUDE_FILE_SPLIT}
                -P ${CLASSIFY_SCRIPT}
        )
    endif()

    add_custom_command(
        OUTPUT ${CUSTOM_COMMAND_OUTPUTS}
        ${CUSTOM_COMMAND_COMMANDS}
        DEPENDS ${DEPENDENT_TARGETS} ${RTL_SOURCES}
        WORKING_DIRECTORY ${COMMAND_WORKING_DIRECTORY}
        COMMENT "Generating list of the RTL source files in ${OUTDIR}"
        VERBATIM
    )

    set(DESCRIPTION
        "Generate dependency-ordered Verilog/SystemVerilog source list for ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}"
    )

    if(ARG_TARGET_NAME_SUFFIX)
        set(TARGET_NAME ${IP_LIB}_source_list_${ARG_TARGET_NAME_SUFFIX})
    else()
        set(TARGET_NAME ${IP_LIB}_source_list)
    endif()

    add_custom_target(
        ${TARGET_NAME}
        DEPENDS ${CUSTOM_COMMAND_OUTPUTS}
        COMMENT ${DESCRIPTION}
        VERBATIM
    )

    set_property(
        TARGET ${TARGET_NAME}
        PROPERTY DESCRIPTION ${DESCRIPTION}
    )
endfunction()
