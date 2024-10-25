#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium simulation on IP_LIB.
#
# It will create a target **run_<IP_LIB>_xcelium** that will compile, elaborate and run the xcelium simulation
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword GUI: launch SimVision gui together with the simulation
# :type GUI: boolean
#]]

include_guard(GLOBAL)

function(xcelium_run IP_LIB)
    cmake_parse_arguments(ARG "GUI" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(ARG_GUI)
        set(ARG_GUI -gui -access +rwc)
    else()
        unset(ARG_GUI)
    endif()

    # Get RTL and TB sources
    get_ip_rtl_sources(SOURCES ${IP_LIB})
    get_ip_tb_only_rtl_sources(TB_SOURCES ${IP_LIB})
    list(APPEND SOURCES ${TB_SOURCES})

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INC_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -incdir ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG) # TODO Add VHDL??
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND xrun
        # Enable parameters without default value
        -setenv CADENCE_ENABLE_AVSREQ_44905_PHASE_1=1 -setenv CADENCE_ENABLE_AVSREQ_63188_PHASE_1=1
        -define COMMON_CELLS_ASSERTS_OFF
        ${SOURCES}
        ${ARG_INCDIRS}
        ${CMP_DEFS_ARG}
        ${ARG_GUI}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        DEPENDS ${SOURCES} ${IP_LIB}
    )
endfunction()

#[[[
# Create a target for invoking Xcelium compilation and elaboration on IP_LIB.
#
# It will create a target **<IP_LIB>_xcelium_elab** that will compile and elaborate the design
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword ACCESS: Access rights (i.e., visibility) used to compile and elaborate the design. For debugging pass 'rwc'
# :type ACCESS: string
# :keyword SETENV: List of env variables passed to xrun
# :type SETENV: string
# :keyword DEFINES: List of defines passed to xrun
# :type DEFINES: string
# :keyword ARGS: Additional arguments passed to xrun
# :type ARGS: string
#]]
function(xcelium_elab IP_LIB)
    cmake_parse_arguments(ARG "" "ACCESS" "SETENV;DEFINES;ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/uniquify_files_by_basename.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Get RTL and TB sources
    get_ip_rtl_sources(SOURCES_LIST ${IP_LIB})
    get_ip_tb_only_rtl_sources(TB_SOURCES_LIST ${IP_LIB})
    list(APPEND SOURCES_LIST ${TB_SOURCES_LIST})

    # uniquify the list of files to avoid redefinition
    # This function also check files with same basename have the same content
    uniquify_files_by_basename(SOURCES_LIST_UNIQUIFY "${SOURCES_LIST}")

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INC_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    foreach(dir ${INC_DIRS})
        list(APPEND INCDIR_LIST -incdir ${dir})
    endforeach()
    # message("ARG_SETENV: ${ARG_SETENV}")
    foreach(var ${ARG_SETENV})
        list(APPEND SETENV_LIST -setenv ${var})
    endforeach()
    # message("ARG_DEFINES: ${ARG_DEFINES}")
    foreach(def ${ARG_DEFINES})
        list(APPEND DEFINES_LIST -define ${def})
    endforeach()

    if(${TIMESCALE_ARG})
        set(TIMESCALE_ARG -timescale ${TIMESCALE_ARG})
    else()
        set(TIMESCALE_ARG -timescale 1ps/1ps)
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
        COMMAND xrun -elaborate
        # xrun compiler options
        ${SETENV_LIST}
        ${DEFINES_LIST}
        ${CMP_DEFS_LIST}
        # SystemVerilog language constructs enabled by default
        -sv
        # xrun elaboration options
        ${ACCESS_ARG}
        ${TIMESCALE_ARG}
        # Miscellaneous arguments
        ${ARG_ARGS}
        # Source files and include directories
        ${SOURCES_LIST_UNIQUIFY}
        ${INCDIR_LIST}
        BYPRODUCTS xcelium.d xrun.history xrun.key xrun.log
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        DEPENDS ${SOURCES_LIST} ${IP_LIB}
    )

endfunction()
