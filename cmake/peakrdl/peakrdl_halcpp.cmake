#[[[ @module peakrdl_halcpp
#]]

#[[[
# Create a target for invoking PeakRDL-halcpp on RTLLIB.
#
# PeakRDL-halcpp generates a C++ 17 Hardware Abstraction Layer (HAL) drivers based on SystemRDL description.
# PeakRDL-halcpp can be found on this `link <https://github.com/Risto97/PeakRDL-halcpp>`_
#
# Function expects that **RTLLIB** *INTERFACE_LIBRARY* has **RDL_FILES** property set with a list of SystemRDL files to be used as inputs.
# To set the RDL_FILES property use `set_property() <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function:
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY RDL_FILES ${PROJECT_SOURCE_DIR}/file.rdl)
#
#
# Function will append CPP source files to the **FILE_SET** **HEADERS** of the **RTLLIB**.
#
# If the **RLTLLIB** has a header file called **RTLLIB_ext.h** added to **FILE_SET** **HEADERS**, that module will be passed to peakrdl-halcpp as \-\-ext argument.
# Meaning that the extended class will be used in the hierarchy instead of the HAL generated one.
# The function works recursively, so its enough to call it once on the top library of the hierarchy.
#
# To set the extended class to the library this code snippet can be used
#
# .. code-block:: c++
#
#    target_sources(<lib> INTERFACE FILE_SET HEADERS 
#        BASE_DIRS "${PROJECT_SOURCE_DIR}/firmware/hal"
#        FILES "firmware/hal/<lib>_ext.h"
#        )
#
# :param RTLLIB: RTL interface library, it needs to have RDL_FILES property set with a list of SystemRDL files.
# :type RTLLIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/halcpp will be used.
# :type OUTDIR: string path
#]]
function(peakrdl_halcpp RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/halcpp)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    __ext_header_provided(${RTLLIB} libs)
    list(LENGTH libs libs_len)
    if(libs_len GREATER 0)
        set(EXT_ARG --ext ${libs})
    endif()

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    set(__CMD 
        python3 -m peakrdl halcpp
            ${RDL_FILES}
            ${EXT_ARG}
            -o ${OUTDIR} 
        )
    set(__CMD_LF ${__CMD} --list-files)

    # Call peakrdl-halcpp with --list-files option to get the list of headers
    execute_process(
        OUTPUT_VARIABLE CPP_HEADERS
        ERROR_VARIABLE HALCPP_ERROR
        COMMAND ${__CMD_LF}
        )
    if(CPP_HEADERS)
        string(REPLACE " " ";" CPP_HEADERS "${CPP_HEADERS}") # TOOD verify
        string(REPLACE "\n" "" CPP_HEADERS "${CPP_HEADERS}")
        list(REMOVE_DUPLICATES CPP_HEADERS)
    else()
        string(REPLACE ";" " " __CMD_STR "${__CMD}")
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${RTLLIB}, output of --list-files option: ${CPP_HEADERS} error output: ${HALCPP_ERROR} \n Command Called: \n ${__CMD_STR}")
    endif()

    set_source_files_properties(${CPP_HEADERS} PROPERTIES GENERATED TRUE)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY INTERFACE ${GRAPHIC_FILES})
    target_sources(${RTLLIB} INTERFACE
        FILE_SET HEADERS 
        BASE_DIRS ${OUTDIR}
        FILES ${CPP_HEADERS}
        )

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${CPP_HEADERS} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_halcpp
        DEPENDS ${CPP_HEADERS} ${STAMP_FILE}
        )

    add_dependencies(${RTLLIB} ${RTLLIB}_halcpp)

endfunction()

# Find headers that have _ext.h extension and compare with libraries
# If there is a library that matches the file name add it to list
function(__ext_header_provided LIB libs)
    get_rtl_target_property(HEADERS ${LIB} HEADER_SET)
    get_rtl_target_property(FLAT_GRAPH ${LIB} FLAT_GRAPH)

    
    foreach(h ${HEADERS})
        get_filename_component(fn ${h} NAME)
        string(FIND ${fn} "_ext.h" ext_found)
        if(NOT ext_found EQUAL -1)
            foreach(l ${FLAT_GRAPH})
                string(FIND ${fn} ${l} match)
                if(NOT match EQUAL -1)
                    list(APPEND ext_libs ${l})
                endif()
            endforeach()
        endif()
    endforeach()

    list(REMOVE_DUPLICATES ext_libs)
    set(${libs} ${ext_libs} PARENT_SCOPE)

endfunction()


