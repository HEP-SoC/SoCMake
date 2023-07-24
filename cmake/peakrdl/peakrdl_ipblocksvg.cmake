#[[[ @module peakrdl_ipblocksvg
#]]

#[[[
# Create a target for invoking PeakRDL-ipblocksvg on RTLLIB.
#
# PeakRDL-ipblocksvg generates IP block diagram like the one shown below.
#
# .. image:: ../../graphics/scr1_soc_top.png
#  :width: 400
#  :alt: Generated IP block diagram
#
#
# PeakRDL-ipblocksvg can be found on this `link <https://github.com/Risto97/PeakRDL-ipblocksvg>`_
#
# It is important to have `inkscape <https://inkscape.org/>`_ installed on the system for this function to work.
#
# Function expects that **RTLLIB** *INTERFACE_LIBRARY* has **RDL_FILES** property set with a list of SystemRDL files to be used as inputs.
# To set the RDL_FILES property use `set_property() <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function:
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY RDL_FILES ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# Function will append  .png files to the **GRAPHIC_FILES** of the **RTLLIB**.
#
#
# :param RTLLIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/ipblocksvg will be used.
# :type OUTDIR: string path
# :keyword TRAVERSE: option argument if passed, it will traverse the hierarchy and generate a .png file for each addrmap
# :type TRAVERSE: option
# :keyword LOGO: a logo can be placed in the middle of generated picture like shown in figure above.
# :type LOGO: string path
#]]
function(peakrdl_ipblocksvg RTLLIB)
    cmake_parse_arguments(ARG "TRAVERSE" "OUTDIR;LOGO" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/ipblocksvg)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_LOGO)
        set(ARG_LOGO --logo ${ARG_LOGO})
    endif()

    if(ARG_TRAVERSE)
        set(ARG_TRAVERSE --traverse)
    endif()

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD 
        ${Python3_EXECUTABLE} -m peakrdl ipblocksvg 
            ${RDL_FILES}
            ${ARG_LOGO}
            ${ARG_TRAVERSE}
            -o ${OUTDIR}
            )
    set(__CMD_LF ${__CMD} --list-files)

    execute_process(
        OUTPUT_VARIABLE GRAPHIC_FILES
        ERROR_VARIABLE IPLBOCKSVG_ERROR
        COMMAND ${__CMD_LF}
        )
    if(GRAPHIC_FILES)
        string(REPLACE " " ";" GRAPHIC_FILES "${GRAPHIC_FILES}")
        string(REPLACE "\n" "" GRAPHIC_FILES "${GRAPHIC_FILES}")
        list(REMOVE_DUPLICATES GRAPHIC_FILES)
    else()
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${RTLLIB}, output of --list-files option: ${GRAPHIC_FILES} error output: ${IPLBOCKSVG_ERROR}")
    endif()

    set_source_files_properties(${GRAPHIC_FILES} PROPERTIES GENERATED TRUE)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY GRAPHIC_FILES ${GRAPHIC_FILES})

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${GRAPHIC_FILES} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${GRAPHIC_FILES} ${STAMP_FILE}
        )

    # set_property(TARGET ${RTLLIB} APPEND PROPERTY DEPENDS ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})
    add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION} )
endfunction()

