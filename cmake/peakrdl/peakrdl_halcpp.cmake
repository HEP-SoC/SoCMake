#[[[
# Create a target for invoking PeakRDL-halcpp on IP_LIB.
#
# PeakRDL-halcpp generates a C++ 17 Hardware Abstraction Layer (HAL) drivers based on
# SystemRDL description. PeakRDL-halcpp can be found on this
# `link <https://github.com/Risto97/PeakRDL-halcpp>`_
#
# Function expects that **IP_LIB** *INTERFACE_LIBRARY* has **SYSTEMRDL_SOURCES** property set
# with a list of SystemRDL files to be used as inputs. To set the SYSTEMRDL_SOURCES property use
# the ip_sources() function from SoCMake (internally using `set_property()
# <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function):
#
# .. code-block:: cmake
#
#    ip_sources(IP_LIB LANGUAGE [SYSTEMRDL|SYSTEMVERILOG|...] ${PROJECT_SOURCE_DIR}/file.rdl)
#
# This function will append CPP source files to the **FILE_SET** **HEADERS** of the **IP_LIB**.
#
# If the **IP_LIB** has a header file called **IP_LIB_ext.h** added to **FILE_SET** **HEADERS**,
# that module will be passed to peakrdl-halcpp as \-\-ext argument. Meaning that the extended class
# will be used in the hierarchy instead of the HAL generated one.
# The function works recursively, so its enough to call it once on the top library of the hierarchy.
#
# To set the extended class to the library this code snippet can be used:
#
# .. code-block:: c++
#
#    target_sources(<lib> INTERFACE FILE_SET HEADERS
#        BASE_DIRS "${PROJECT_SOURCE_DIR}/firmware/hal"
#        FILES "firmware/hal/<lib>_ext.h"
#    )
#
# :param IP_LIB: RTL interface library, it needs to have SYSTEMRDL_SOURCES property set with a list of SystemRDL files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/halcpp will be used.
# :type OUTDIR: string path
#]]
function(peakrdl_halcpp IP_LIB)
    cmake_parse_arguments(ARG "SKIP_BUSES" "OUTDIR" "PARAMETERS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/halcpp)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Used to overwrite the top level parameters
    set(OVERWRITTEN_PARAMETERS "")
    if(ARG_PARAMETERS)
        foreach(PARAM ${ARG_PARAMETERS})
            set(OVERWRITTEN_PARAMETERS "${OVERWRITTEN_PARAMETERS}" "-P${PARAM}")
        endforeach()
    endif()

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

    __ext_header_provided(${IP_LIB} libs)
    list(LENGTH libs libs_len)
    if(libs_len GREATER 0)
        set(EXT_ARG --ext ${libs})
    endif()

    if(ARG_SKIP_BUSES)
        set(SKIB_BUSES_ARG --skip-buses)
    endif()

    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set,
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
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl halcpp
            ${RDL_FILES}
            ${EXT_ARG}
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            ${SKIB_BUSES_ARG} -o ${OUTDIR}
            ${OVERWRITTEN_PARAMETERS}
    )

    target_include_directories(${IP_LIB} INTERFACE ${OUTDIR} ${OUTDIR}/include)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${CPP_HEADERS} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_halcpp
        DEPENDS ${CPP_HEADERS} ${STAMP_FILE}
        )

    add_dependencies(${IP_LIB} ${IP_LIB}_halcpp)

endfunction()

#[[[
# Find headers that have _ext.h extension and compare with libraries. If there is a library that
# matches the file name add it to list.
#]]
function(__ext_header_provided LIB libs)
    get_ip_property(HEADERS ${LIB} HEADER_SET)
    get_ip_property(FLAT_GRAPH ${LIB} FLAT_GRAPH)

    foreach(h ${HEADERS})
        get_filename_component(fn ${h} NAME)
        string(FIND ${fn} "_ext.h" ext_found)
        if(NOT ext_found EQUAL -1)
            foreach(l ${FLAT_GRAPH})
                get_target_property(ip_name ${l} IP_NAME)
                string(FIND ${fn} ${ip_name} match)
                if(NOT match EQUAL -1)
                    list(APPEND ext_libs ${ip_name})
                endif()
            endforeach()
        endif()
    endforeach()

    list(REMOVE_DUPLICATES ext_libs)
    set(${libs} ${ext_libs} PARENT_SCOPE)

endfunction()
