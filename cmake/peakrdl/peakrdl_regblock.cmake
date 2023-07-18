#[[[ @module peakrdl_regblock
#]]

#[[[
# Create a target for invoking PeakRDL-regblock on RTLLIB.
#
# :param RTLLIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/regblock will be used.
# :type OUTDIR: string path
# :keyword INTF: Interface to use for the regblock possible values: [passthrough, apb3, apb3-flat, apb4, apb4-flat, axi4-lite, axi4-lite-flat, avalon-mm, avalon-mm-flat]
# :type INTF: string
#]]
function(peakrdl_regblock RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "INTF" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/regblock)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_INTF)
        set(INTF_ARG --cpuif ${ARG_INTF})
    endif()
    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)


    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    set(V_GEN 
        ${OUTDIR}/${RTLLIB}_regblock_pkg.sv
        ${OUTDIR}/${RTLLIB}_regblock.sv
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
        COMMAND peakrdl regblock 
            --rename ${RTLLIB}_regblock
            ${INTF_ARG}
            -o ${OUTDIR} 
            ${RDL_FILES}

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
