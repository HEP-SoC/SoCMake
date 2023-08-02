#[[[ @module peakrdl_regblock
#]]

#[[[
# Create a target for invoking PeakRDL-regblock on IP_LIB.
#
# PeakRDL-regblock is transforming SystemRDL input files to SystemVerilog register block files.
# Regblock documentation can be found on this `link <https://peakrdl-regblock.readthedocs.io/en/latest/>`_
#
# Function expects that **${IP_LIB}** *INTERFACE_LIBRARY* has **RDL_FILES** property set with a list of SystemRDL files to be used as inputs.
# To set the RDL_FILES property use `set_property() <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function:
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY RDL_FILES ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# Function will append 2 generated files from PeakRDL-regblock to the **SOURCES** property of the **${IP_LIB}**
#
# :param IP_LIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/regblock will be used.
# :type OUTDIR: string path
# :keyword RENAME: Rename the generated module and file name to a custom string, otherwise the name will be ${IP_LIB}.sv.
# :type RENAME: string
# :keyword INTF: Interface to use for the regblock possible values: [passthrough, apb3, apb3-flat, apb4, apb4-flat, axi4-lite, axi4-lite-flat, avalon-mm, avalon-mm-flat]
# :type INTF: string
#]]
function(peakrdl_regblock IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;RENAME;INTF" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/regblock)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_RENAME)
        get_target_property(MOD_NAME ${IP_LIB} IP_NAME)
        if(NOT MOD_NAME)
            message(FATAL_ERROR "IP_NAME not set for ${IP_LIB}, check if the IP was added with add_ip function from SoCMake")
        endif()
        set(MOD_NAME ${MOD_NAME}_regblock)
    else()
        set(MOD_NAME ${ARG_RENAME})
    endif()

    if(ARG_INTF)
        set(INTF_ARG --cpuif ${ARG_INTF})
    endif()

    get_ip_sources(RDL_SOURCES ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_SOURCES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have SYSTEMRDL_SOURCES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock 
            --rename ${MOD_NAME}
            ${INTF_ARG}
            -o ${OUTDIR} 
            ${RDL_SOURCES} 
        )

    set(SV_GEN 
        ${OUTDIR}/${MOD_NAME}_pkg.sv
        ${OUTDIR}/${MOD_NAME}.sv
        )
    set_source_files_properties(${SV_GEN} PROPERTIES GENERATED TRUE)
    ip_sources(${IP_LIB} SYSTEMVERILOG PREPEND ${SV_GEN})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${SV_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_regblock
        DEPENDS ${SV_GEN} ${STAMP_FILE}
        )

    add_dependencies(${IP_LIB} ${IP_LIB}_regblock)
    set_property(TARGET ${IP_LIB} APPEND PROPERTY DEPENDS ${IP_LIB}_regblock)

endfunction()
