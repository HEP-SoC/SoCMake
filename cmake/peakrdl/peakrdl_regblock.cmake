#[[[ @module peakrdl_regblock
#]]

#[[[
# Create a target for invoking PeakRDL-regblock on RTLLIB.
#
# PeakRDL-regblock is transforming SystemRDL input files to SystemVerilog register block files.
# Regblock documentation can be found on this `link <https://peakrdl-regblock.readthedocs.io/en/latest/>`_
#
# Function expects that **${RTLLIB}** *INTERFACE_LIBRARY* has **RDL_FILES** property set with a list of SystemRDL files to be used as inputs.
# To set the RDL_FILES property use `set_property() <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function:
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY RDL_FILES ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# Function will append 2 generated files from PeakRDL-regblock to the **SOURCES** property of the **${RTLLIB}**
#
# :param RTLLIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/regblock will be used.
# :type OUTDIR: string path
# :keyword RENAME: Rename the generated module and file name to a custom string, otherwise the name will be ${RTLLIB}.sv.
# :type RENAME: string
# :keyword INTF: Interface to use for the regblock possible values: [passthrough, apb3, apb3-flat, apb4, apb4-flat, axi4-lite, axi4-lite-flat, avalon-mm, avalon-mm-flat]
# :type INTF: string
#]]
function(peakrdl_regblock RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR;RENAME;INTF" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/regblock)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_RENAME)
        set(MOD_NAME ${RTLLIB}_regblock)
    else()
        set(MOD_NAME ${ARG_RENAME})
    endif()

    if(ARG_INTF)
        set(INTF_ARG --cpuif ${ARG_INTF})
    endif()
    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)


    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock 
            --rename ${MOD_NAME}
            ${INTF_ARG}
            -o ${OUTDIR} 
            ${RDL_FILES} 
        )

    set(V_GEN 
        ${OUTDIR}/${MOD_NAME}_pkg.sv
        ${OUTDIR}/${MOD_NAME}.sv
        )
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)
    get_target_property(TARGET_SOURCES ${RTLLIB} SOURCES)
    if(NOT TARGET_SOURCES)
        set(TARGET_SOURCES "")
    endif()
    set_property(TARGET ${RTLLIB} PROPERTY SOURCES ${V_GEN} ${TARGET_SOURCES} )

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_regblock
        DEPENDS ${V_GEN} ${STAMP_FILE}
        )

    add_dependencies(${RTLLIB} ${RTLLIB}_regblock)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY DEPENDS ${RTLLIB}_regblock)

endfunction()
