#[[[ @module peakrdl_html
#]]

#[[[
# Create a target for invoking PeakRDL-html on IP_LIB.
#
# `PeakRDL-html <https://github.com/SystemRDL/PeakRDL-html>` generates HTML documentation out of the SystemRDL inputs.
# 
# An example of generated documentation can be found `here <https://systemrdl.github.io/PeakRDL-html/?p=>`_
#
# Function expects that **${IP_LIB}** has **SYSTEMRDL_SOURCES** property set with
# a list of SystemRDL files to be used as inputs. To set the SYSTEMRDL_SOURCES property use the ip_sources()
#
# .. code-block:: cmake
#
#    ip_sources(ip SYSTEMRDL ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# :param IP_LIB: IP for which to create html target.
# :type IP_LIB: IP library
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated.
# If ommited ${BINARY_DIR}/html will be used.
# :type OUTDIR: string
# :keyword SERVER_TARGET: option argument if passed it will also launch the local server on `https://0.0.0.0:8000 <https://0.0.0.0:8000>`_
# :type SERVER_TARGET: option
# :keyword ARGS: any additional arguments to pass to peakrdl cli
# :type ARGS: list
#]]
function(peakrdl_html IP_LIB)
    cmake_parse_arguments(ARG "SERVER_TARGET" "OUTDIR" "ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
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

    get_ip_sources(RDL_SOURCES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_SOURCES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_SOURCES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
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
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl html
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            -o ${OUTDIR}
            ${RDL_SOURCES}
            ${ARG_ARGS}
            )

    ## Try to estimate the generated files, mostly for `make clean` purposes
    ## It is dangerous to put whole OUTDIR as BYPRODUCTS/OUTPUT, this way risk is a bit lower
    set(GENERATED_FILES 
            ${OUTDIR}/content
            ${OUTDIR}/css
            ${OUTDIR}/data
            ${OUTDIR}/favicon.png
            ${OUTDIR}/fonts
            ${OUTDIR}/index.html
            ${OUTDIR}/js
            ${OUTDIR}/launcher-windows-chrome.bat
            ${OUTDIR}/launcher-windows-edge.bat
            ${OUTDIR}/launcher-windows-firefox.bat
            ${OUTDIR}/search
        )

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    set(DESCRIPTION "Generate html documentation for \"${IP_LIB}\", with ${CMAKE_CURRENT_FUNCTION}")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${GENERATED_FILES}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES} ${IP_LIB}
        COMMAND_EXPAND_LISTS
        COMMENT ${DESCRIPTION}
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${GENERATED_FILES}
        )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

    if(ARG_SERVER_TARGET)
        set(DESCRIPTION "Run a server for html documentation of \"${IP_LIB}\", generated with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_server
            WORKING_DIRECTORY ${OUTDIR}
            COMMAND ${Python3_EXECUTABLE} -m http.server
            DEPENDS ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            )
        set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_server PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

endfunction()
