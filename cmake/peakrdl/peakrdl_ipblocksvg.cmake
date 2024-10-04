#[[[
# Create a target for invoking PeakRDL-ipblocksvg on IP_LIB.
#
# PeakRDL-ipblocksvg generates IP block diagram like the one shown below.
#
# .. image:: ../../graphics/scr1_soc_top.png
#  :width: 400
#  :alt: Generated IP block diagram
#
#
# PeakRDL-ipblocksvg can be found on this `link <https://github.com/Risto97/PeakRDL-ipblocksvg>`_.
# It is important to have `inkscape <https://inkscape.org/>`_ installed on the system for this
# function to work. Function expects that **IP_LIB** *INTERFACE_LIBRARY* has **SYSTEMRDL_SOURCES**
# property set with a list of SystemRDL files to be used as inputs. To set the SYSTEMRDL_SOURCES
# property use the ip_sources() function from SoCMake (internally using `set_property()
# <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function):
#
# .. code-block:: cmake
#
#    ip_sources(IP_LIB LANGUAGE [SYSTEMRDL|SYSTEMVERILOG|...] ${PROJECT_SOURCE_DIR}/file.rdl)
#
# This function will append .png files to the **GRAPHIC_FILES** of the **IP_LIB**.
#
#
# :param IP_LIB: RTL interface library, it needs to have SYSTEMRDL_SOURCES property set with a list
# of SystemRDL files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword OUTDIR: output directory in which the files will be generated, if ommited
# ${BINARY_DIR}/ipblocksvg will be used.
# :type OUTDIR: string path
# :keyword TRAVERSE: option argument if passed, it will traverse the hierarchy and generate a .png
# file for each addrmap
# :type TRAVERSE: option
# :keyword APPEND_HIERPATH: Append hierarchical path to the output directory, for example if outdir
# is /home/user/test/ and hierarchy of Addrmap is soc.apb_subsystem.plic the output directory will be /home/user/test/soc/apb_subsystem/plic, use PATH_SUFFIX to append additional suffix to this path
# :type APPEND_HIERPATH: option
# :keyword PATH_SUFFIX: Append a path suffix to the output directory, for example if
# --path-suffix=docs/pictures and outdir is /home/user/test/, and APPEND_HIERPATH is active,
# addrmap hierarchy is soc.apb_subsystem.plic, the real output path will be
# /home/user/test/soc/apb_subsystem/plic/docs/pictures/
# :type PATH_SUFFIX: string
# :keyword LOGO: a logo can be placed in the middle of generated picture like shown in figure above.
# :type LOGO: string path
#]]
function(peakrdl_ipblocksvg IP_LIB)
    cmake_parse_arguments(ARG "TRAVERSE;APPEND_HIERPATH" "OUTDIR;LOGO;PATH_SUFFIX" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

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

    if(ARG_APPEND_HIERPATH)
        set(ARG_APPEND_HIERPATH --append-hierpath)
    else()
        unset(ARG_APPEND_HIERPATH)
    endif()

    if(ARG_PATH_SUFFIX)
        set(ARG_PATH_SUFFIX --path-suffix ${ARG_PATH_SUFFIX})
    else()
        unset(ARG_PATH_SUFFIX)
    endif()

    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

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
    set(__CMD
        ${Python3_EXECUTABLE} -m peakrdl ipblocksvg
            ${RDL_FILES}
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            ${ARG_LOGO}
            ${ARG_TRAVERSE}
            ${ARG_APPEND_HIERPATH}
            ${ARG_PATH_SUFFIX}
            -o ${OUTDIR}
            )
    set(__CMD_LF ${__CMD} --list-files)

    execute_process(
        OUTPUT_VARIABLE GRAPHIC_FILES
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${__CMD_LF}
        )
    if(GRAPHIC_FILES)
        string(REPLACE " " ";" GRAPHIC_FILES "${GRAPHIC_FILES}")
        string(REPLACE "\n" "" GRAPHIC_FILES "${GRAPHIC_FILES}")
        list(REMOVE_DUPLICATES GRAPHIC_FILES)
    else()
        string(REPLACE ";" " " __CMD_STR "${__CMD}")
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${IP_LIB},
                output of --list-files option: ${V_GEN} error output: ${ERROR_MSG} \n
                Command Called: \n ${__CMD_STR}")
    endif()

    set_source_files_properties(${GRAPHIC_FILES} PROPERTIES GENERATED TRUE)
    ip_sources(${IP_LIB} GRAPHIC ${GRAPHIC_FILES})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${GRAPHIC_FILES} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${GRAPHIC_FILES} ${STAMP_FILE}
        )

    add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()
