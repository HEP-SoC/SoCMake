include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../sv2v.cmake)

# [[[
# This function runs the Yosys synthesis tool on a specified IP library.
#
# The function is a wrapper around the Yosys tool and generates necessary scripts
# and configurations to run Yosys on the specified IP library.
#
# :param IP_LIB: Name of the IP library to run Yosys on.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory for Yosys results. Defaults to BINARY_DIR/yosys.
# :type OUTDIR: string
# :keyword TOP: Top module name. Defaults to IP_NAME.
# :type TOP: string
# :keyword PLUGINS: List of Yosys plugins to use (shared or static libraries).
# :type PLUGINS: list
# :keyword SCRIPTS: List of Yosys script files to use. Defaults to default.ys.
# :type SCRIPTS: list
# :keyword SV2V: Convert SystemVerilog sources to Verilog using sv2v tool.
# :type SV2V: boolean
# :keyword SHOW: Generate additional Yosys script to show the netlist.
# :type SHOW: boolean
# :keyword REPLACE: Replace original sources with the generated Verilog source.
# :type REPLACE: boolean
# ]]]
function(yosys IP_LIB)
    # TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead

    # Parse the function arguments
    cmake_parse_arguments(ARG "SV2V;SHOW;REPLACE" "OUTDIR;TOP;PLUGINS;SCRIPTS" "" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Include the hardware IP managament main functions
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    # Assume the IP library is the latest one provided if full name is not given
    ip_assume_last(IP_LIB ${IP_LIB})
    # Get the binary directory of the IP library
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Set the output directory for Yosys results
    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/yosys)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Set the top module name
    if(NOT ARG_TOP)
        get_target_property(TOP_MODULE ${IP_LIB} TOP_MODULE)
        if(NOT TOP_MODULE)
            # Use the IP name is top module name is not given
            get_target_property(IP_NAME ${IP_LIB} IP_NAME)
            set(TOP_MODULE ${IP_NAME})
        endif()
    else()
        set(TOP_MODULE ${ARG_TOP})
    endif()

    # If SV2V argument is passed and the target does not exist, convert SystemVerilog to Verilog
    if(ARG_SV2V AND NOT TARGET ${IP_LIB}_sv2v)
        message("Yosys ${IP_LIB}: sv2v argument call")
        # Replace the original files with the generated ones
        sv2v(${IP_LIB} REPLACE)
    else()
        message("Yosys ${IP_LIB}: sv2v argument NOT call")
        # Otherwise use original source files
        get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG)
        list(REMOVE_DUPLICATES SOURCES)
    endif()

    # Get the RTL sources (sv files are replaced if SV2V arg is passed)
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG)

    # Format the string for config file format
    string (REPLACE ";" " " V_FILES_STR "${SOURCES}")

    message("Yosys V_FILES_STR: ${V_FILES_STR}")

    # Get the IP compile definitions (e.g., )
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)
    # Prepend '-D' to all definitions
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    # Set the generated netlist verilog file path
    set(V_GEN ${OUTDIR}/${IP_LIB}.v)
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    # If no custom scripts are provided, use the default Yosys script
    if(NOT ARG_SCRIPTS)
        set(YOSYS_SCRIPTS ${OUTDIR}/flows/default_${IP_LIB}.ys)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/default.ys.in ${YOSYS_SCRIPTS} @ONLY)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${YOSYS_SCRIPTS})
    else()
        foreach(_script ${ARG_SCRIPTS})
            # Configure and set the custom scripts
            get_filename_component(__ext ${_script} EXT)
            get_filename_component(__fn ${_script} NAME_WLE)
            if(__ext STREQUAL ".ys.in")
                configure_file(${_script} ${OUTDIR}/flows/${__fn} @ONLY)
                set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/${__fn})
                list(APPEND YOSYS_SCRIPTS ${OUTDIR}/flows/${__fn})
            endif()
        endforeach()
    endif()

    # If SHOW argument is passed, configure an additional Yosys script to show the netlist
    if(ARG_SHOW)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/flows/show.ys.in ${OUTDIR}/flows/show_${IP_LIB}.ys @ONLY)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR}/flows/show_${IP_LIB}.ys)
        list(PREPEND YOSYS_SCRIPTS ${OUTDIR}/flows/show_${IP_LIB}.ys)
    endif()

    # If PLUGINS argument is passed, set the plugins for Yosys
    if(ARG_PLUGINS)
        unset(__PLUGINS_ARG)
        foreach(plugin ${ARG_PLUGINS})
            get_target_property(__type ${plugin} TYPE)
            # Add the '-m' flag for each shared and static library plugin provided
            if(${__type} STREQUAL "SHARED_LIBRARY" OR ${__type} STREQUAL "STATIC_LIBRARY")
                list(APPEND __PLUGINS_ARG -m $<TARGET_FILE:${plugin}>)
            else()
                message(FATAL_ERROR "Only Shared and Static libraries are supported for Yosys PLUGINS at the moment")
            endif()
        endforeach()
    endif()

    # Set the stamp file path used as the generated output of the custom command
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    # Add a custom command to run Yosys
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND yosys ${CMP_DEFS_ARG} -s ${YOSYS_SCRIPTS} ${__PLUGINS_ARG}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )
    # Custom target that depends on the stamp file, sources, and yosys scripts
    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SOURCES} ${YOSYS_SCRIPTS}
    )

    # Add

    # If REPLACE argument is passed, replace the original sources with the generated Verilog source
    if(ARG_REPLACE)
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_GEN})
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES "")
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()

