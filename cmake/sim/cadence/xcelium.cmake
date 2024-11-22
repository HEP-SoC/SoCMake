#[[[
# Create a target for invoking Xcelium (compilation, elaboration, and simulation) on IP_LIB.
#
# It will create a target **<IP_LIB>_xcelium_elab** that will compile, elaborate, and simulate the IP_LIB design.
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword ELABORATE: sets xrun to compile and elaborate only the design (no simulation).
# :type ELABORATE: string
# :keyword UNIQUIFY: Uniquifies the list of ip sources based on the basename of the files: WARNING or FATAL_ERROR.
# :type UNIQUIFY: string
# :keyword SYNTHESIS: Prevents behavioural/generic RTL files to be fetched.
# :type SYNTHESIS: string
# :keyword ACCESS: Access rights (i.e., visibility) used to compile and elaborate the design. For debugging pass 'rwc'.
# :type ACCESS: string
# :keyword SETENV: List of env variables passed to xrun.
# :type SETENV: string
# :keyword DEFINES: List of defines passed to xrun.
# :type DEFINES: string
# :keyword ARGS: Additional arguments passed to xrun.
# :type ARGS: string
#]]
function(xcelium IP_LIB)
    cmake_parse_arguments(ARG "ELABORATE;SYNTHESIS" "UNIQUIFY;ACCESS;TIMESCALE;SDF_CMD_FILE" "SETENV;DEFINES;ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/uniquify_files_by_basename.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Get RTL and TB sources
    get_ip_rtl_sources(SOURCES_LIST ${IP_LIB})
    if(NOT ${ARG_SYNTHESIS})
        get_ip_sim_only_sources(SIM_SOURCES_LIST ${IP_LIB})
        list(PREPEND SOURCES_LIST ${SIM_SOURCES_LIST})
    endif()
    get_ip_tb_only_rtl_sources(TB_SOURCES_LIST ${IP_LIB})
    list(APPEND SOURCES_LIST ${TB_SOURCES_LIST})

    # Why do I need to this #@!$ NOT?!?!?!
    if(NOT ${ARG_UNIQUIFY})
        if (${ARG_UNIQUIFY} STREQUAL "WARNING" OR ${ARG_UNIQUIFY} STREQUAL "FATAL_ERROR")
            message(DEBUG "xcelium: UNIQUIFY argument is ${ARG_UNIQUIFY}")
            # uniquify the list of files to avoid redefinition (comparing file basenames)
            # This function also check files with same basename have the same content
            uniquify_files_by_basename(SOURCES_LIST_UNIQUIFY "${SOURCES_LIST}" ${ARG_UNIQUIFY})
        else()
            message(WARNING "xcelium: unrecognized UNIQUIFY argument ${ARG_UNIQUIFY}. It should be equal to WARNING or FATAL_ERROR for unquifiy to be applied.")
        endif()
    else()
        message(DEBUG "xcelium: UNIQUIFY argument is not set (value=${ARG_UNIQUIFY})")
        set(SOURCES_LIST_UNIQUIFY ${SOURCES_LIST})
    endif()

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INC_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    # Sets the flag to compile and elaborate only
    if(${ARG_ELABORATE})
        set(ELABORATE_ARG -elaborate)
    endif()

    # Add the xrun parameter for the passed include directories, env variables and verilog defines
    foreach(dir ${INC_DIRS})
        list(APPEND INCDIR_LIST -incdir ${dir})
    endforeach()
    foreach(var ${ARG_SETENV})
        list(APPEND SETENV_LIST -setenv ${var})
    endforeach()
    foreach(def ${ARG_DEFINES})
        list(APPEND DEFINES_LIST -define ${def})
    endforeach()

    # Change the default timescale 1ps/1ps if TIMESCALE argument is passed
    if(${ARG_TIMESCALE})
        set(TIMESCALE_ARG -timescale ${ARG_TIMESCALE})
    else()
        set(TIMESCALE_ARG -timescale 1ps/1ps)
    endif()

    # Check if an SDF command file is passed
    if(ARG_SDF_CMD_FILE)
        set(SDF_CMD_FILE -sdf_cmd_file ${ARG_SDF_CMD_FILE})
    endif()

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG) # TODO Add VHDL??
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_LIST -define ${def})
    endforeach()

    if(${ACCESS_ARG})
        set(ACCESS_ARG -access ${ACCESS_ARG})
    endif()

    add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND xrun ${ELABORATE_ARG}
        # xrun compiler options
        ${SETENV_LIST}
        ${DEFINES_LIST}
        ${CMP_DEFS_LIST}
        ${SDF_CMD_FILE}
        # SystemVerilog language constructs enabled by default
        -sv
        # Set the log file name
        -l xrun_elab.log
        # xrun elaboration options
        ${ACCESS_ARG}
        ${TIMESCALE_ARG}
        # Miscellaneous arguments
        ${ARG_ARGS}
        # Source files and include directories
        ${SOURCES_LIST_UNIQUIFY}
        ${INCDIR_LIST}
        BYPRODUCTS xcelium.d xrun_elab.history xrun_elab.key xrun_elab.log
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        DEPENDS ${SOURCES_LIST} ${IP_LIB}
    )

endfunction()
