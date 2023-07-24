#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium simulation on RTLLIB.
#
# It will create a target **run_<RTLLIB>_xcelium** that will start the xcelium simulation
#
# :param RTLLIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword GUI: launch SimVision gui together with the simulation
# :type GUI: boolean
#]]

include_guard(GLOBAL)

function(xcelium RTLLIB)
    cmake_parse_arguments(ARG "GUI" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(ARG_GUI)
        set(ARG_GUI -gui)
    else()
        unset(ARG_GUI)
    endif()

    get_rtl_target_sources(V_FILES ${RTLLIB})
    get_rtl_target_incdirs(INC_DIRS ${RTLLIB})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -incdir ${dir})
    endforeach()

    add_custom_target( run_${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND xrun
        ${V_FILES}
        ${ARG_INCDIRS}
        ${ARG_GUI}
        DEPENDS ${V_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        DEPENDS ${V_FILES} ${RTLLIB}
        )

    # add_dependencies(${RTLLIB}_${CMAKE_CURRENT_FUNCTION} ${RTLLIB})

endfunction()


