#[[[
# Create a target for invoking PeakRDL-regblock on IP_LIB.
#
# PeakRDL-regblock is transforming SystemRDL input files to SystemVerilog register block files.
# Regblock documentation can be found on this `link <https://peakrdl-regblock.readthedocs.io/en/latest/>`_.
#
# Function expects that **${IP_LIB}** has **SYSTEMRDL_SOURCES** property set with
# a list of SystemRDL files to be used as inputs. To set the SYSTEMRDL_SOURCES property use the ip_sources()
#
# .. code-block:: cmake
#
#    ip_sources(ip SYSTEMRDL ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# This function will append 2 generated files from PeakRDL-regblock to the **SYSTEMVERILOG_SOURCES** property of the
# **${IP_LIB}**.
#
# :param IP_LIB: IP for which to create regblock target.
# :type IP_LIB: IP library
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated.
# If ommited ${BINARY_DIR}/regblock will be used.
# :type OUTDIR: string
# :keyword RENAME: Rename the generated module and file name to a custom string, otherwise the
# name will be ${IP_LIB}.sv.
# :type RENAME: string
# :keyword INTF: Interface to use for the regblock. Possible values are:
# [apb3 (default), apb3-flat, apb4, apb4-flat, axi4-lite, axi4-lite-flat, avalon-mm, avalon-mm-flat, passthrough]
# :type INTF: string
# :keyword RESET: reset type for generated regblock. Possible values are:
# [rst (default), rst,rst_n,arst,arst_n]
# :type RESET: string
# :keyword ARGS: any additional arguments to pass to regblock cli executable
# :type ARGS: list
#]]
function(peakrdl_regblock IP_LIB)
    # Parse keyword arguments
    cmake_parse_arguments(ARG "" "OUTDIR;RENAME;INTF;RESET" "ARGS" ${ARGN})
    # Check for any unknown argument
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_RENAME)
        # The default name is the IP name
        get_target_property(REGBLOCK_NAME ${IP_LIB} IP_NAME)
        set(REGBLOCK_NAME ${REGBLOCK_NAME}_regblock)
    else()
        set(REGBLOCK_NAME ${ARG_RENAME})
    endif()

    # The default interface used is apb3, set another on if the argument exists
    if(NOT ARG_INTF)
        set(ARG_INTF apb3-flat)
    endif()

    # The default reset is active-high and synchronous
    if(ARG_RESET)
        set(RESET_ARG --default-reset ${ARG_RESET})
    endif()

    # Get the SystemRDL sources to generate the register block
    # This function gets the IP sources and the deps
    get_ip_sources(RDL_SOURCES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_SOURCES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have SYSTEMRDL_SOURCES property set,
                unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    unset(INCDIRS_ARG)
    foreach(__incdir ${INC_DIRS})
        list(APPEND INCDIRS_ARG -I${__incdir})
    endforeach()

    unset(COMPDEFS_ARG)
    foreach(__compdefs ${COMP_DEFS})
        list(APPEND COMPDEFS_ARG -D${__compdefs})
    endforeach()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock
            --rename ${REGBLOCK_NAME}
            --cpuif ${ARG_INTF}
            ${RESET_ARG}
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            -o ${OUTDIR}
            ${RDL_SOURCES}
            ${ARG_ARGS}
        )

    set(SV_GEN
        ${OUTDIR}/${REGBLOCK_NAME}_pkg.sv
        ${OUTDIR}/${REGBLOCK_NAME}.sv
        )
    # Prepend the generated files to the IP sources
    ip_sources(${IP_LIB} SYSTEMVERILOG PREPEND ${SV_GEN})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    set(DESCRIPTION "Generate register file for \"${IP_LIB}\" with ${ARG_INTF} bus, with ${CMAKE_CURRENT_FUNCTION}")
    add_custom_command(
        # The output files are automtically marked as GENERATED (deleted by make clean among other things)
        OUTPUT ${SV_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT ${DESCRIPTION}
    )
    # This target triggers the systemverilog register block generation using peakRDL regblock tool (_CMD)
    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${SV_GEN} ${STAMP_FILE}
    )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
    add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()
