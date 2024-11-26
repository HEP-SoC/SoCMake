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
    cmake_parse_arguments(ARG "GUI" "" "ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -incdir ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -define ${def})
    endforeach()

    get_ip_links(IPS_LIST ${IP_LIB})

    unset(__lib_args)
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND __lib_args -sv_lib $<TARGET_FILE_DIR:${ip}>/lib$<TARGET_FILE_BASE_NAME:${ip}>)
        endif()
    endforeach()

    add_custom_target( run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND xrun
        # Enable parameters without default value
        -setenv CADENCE_ENABLE_AVSREQ_44905_PHASE_1=1 -setenv CADENCE_ENABLE_AVSREQ_63188_PHASE_1=1
        -define COMMON_CELLS_ASSERTS_OFF
        ${SOURCES}
        ${ARG_INCDIRS}
        ${CMP_DEFS_ARG}
        ${__lib_args}
        $<$<BOOL:${ARG_GUI}>:-gui>
        ${ARG_ARGS}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        DEPENDS ${SOURCES} ${IP_LIB}
        )

endfunction()


