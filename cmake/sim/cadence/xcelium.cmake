#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium simulation on IP_LIB.
#
# It will create a target **run_<IP_LIB>_xcelium** that will start the xcelium simulation
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

function(xcelium IP_LIB)
    cmake_parse_arguments(ARG "GUI" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(ARG_GUI)
        set(ARG_GUI -gui)
    else()
        unset(ARG_GUI)
    endif()

    get_ip_rtl_sources(SOURCES ${IP_LIB})
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

    add_custom_target( run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
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

    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})

endfunction()


