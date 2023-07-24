#[[[ @module peakrdl_html
#]]

#[[[
# Create a target for invoking PeakRDL-html on RTLLIB.
#
# PeakRDL-html generates HTML documentation out of the SystemRDL inputs.
#
# PeakRDL-html can be found on this `link <https://github.com/SystemRDL/PeakRDL-html>`_
# 
# An example of generated documentation can be found on this `link <https://systemrdl.github.io/PeakRDL-html/?p=>`_
#
# Function expects that **RTLLIB** *INTERFACE_LIBRARY* has **RDL_FILES** property set with a list of SystemRDL files to be used as inputs.
# To set the RDL_FILES property use `set_property() <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function:
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY RDL_FILES ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# :param RTLLIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/html will be used.
# :type OUTDIR: string path
# :keyword SERVER_TARGET: option argument if passed it will also launch the local server on `https://0.0.0.0:8000 <https://0.0.0.0:8000>`_
# :type SERVER_TARGET: option
#]]
function(peakrdl_html RTLLIB)
    cmake_parse_arguments(ARG "SERVER_TARGET" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/html)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD 
        ${Python3_EXECUTABLE} -m peakrdl html
            -o ${OUTDIR}
            ${RDL_FILES}
            )

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${OUTDIR} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES} ${GRAPHIC_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${OUTDIR} ${STAMP_FILE}
        )

    if(ARG_SERVER_TARGET)
        add_custom_target(${RTLLIB}_${CMAKE_CURRENT_FUNCTION}_server
            COMMAND python3 -m http.server -d "${OUTDIR}"
            DEPENDS ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
            )
    endif()

endfunction()


