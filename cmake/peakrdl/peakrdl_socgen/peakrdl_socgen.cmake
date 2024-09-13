#[[[
# Create a target for invoking PeakRDL-socgen on IP_LIB.
#
# PeakRDL-socgen generates top verilog file that connects the IP blocks.
#
# PeakRDL-socgen can be found on this `link <https://gitlab.cern.ch/socmake/PeakRDL-socgen>`_
#
# Function expects that **IP_LIB** *INTERFACE_LIBRARY* has **SYSTEMRDL_SOURCES** property set with a list of
# SystemRDL files to be used as inputs. To set the SYSTEMRDL_SOURCES property use the ip_sources()
# function from SoCMake (internally using `set_property()
# <https://cmake.org/cmake/help/latest/command/set_property.html>`_ CMake function):
#
# .. code-block:: cmake
#
#    ip_sources(IP_LIB LANGUAGE [SYSTEMRDL|SYSTEMVERILOG|...] ${PROJECT_SOURCE_DIR}/file.rdl)
#
# Additionally it is possible to inject custom Verilog code inside the generated verilog code.
# In order to inject files its necessary to do 2 things:
# * Name of the file needs to be <name-of-the-subsystem_<whatever>.v/sv for
# example apb_subsystem_plic_irq.v
# * Set the SOCGEN_INJECT_V_FILES property of IP_LIB like shown below, it is
# possible to provide multiple files. Another option is to pass the parameter INJECT_V_FILES
# as parameter to the function.
#
# .. code-block:: cmake
#
#    set_property(TARGET <your-lib> PROPERTY SOCGEN_INJECT_V_FILES
#                 ${PROJECT_SOURCE_DIR}/apb_subsystem_plic_irq.v)
#
#
# This function will append verilog files generated to the **SOURCES** property of the **IP_LIB**.
#
# PeakRDL-socgen also generates a graphviz .dot file as a visualization of the generated architecture.
#
# :param IP_LIB: RTL interface library, it needs to have SYSTEMRDL_SOURCES property set with a list of SystemRDL files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword USE_INCLUDE: use verilog include preprocessor directive instead of embedding injected
# code directly into generated verilog. By default embedding is used.
# :type USE_INCLUDE: option
# :keyword GEN_DOT: enable generation of graphviz dot file along with verilog files
# :type GEN_DOT: option
# :keyword OUTDIR: output directory in which the files will be generated, if ommited
# ${BINARY_DIR}/socgen will be used.
# :type OUTDIR: string path
# :keyword INJECT_V_FILES: list of Verilog or SV files to be injected into the subsystems.
# :type INJECT_V_FILES: List[string path]
#]]
function(peakrdl_socgen IP_LIB)
    cmake_parse_arguments(ARG "USE_INCLUDE;GEN_DOT" "OUTDIR" "INJECT_V_FILES;PARAMETERS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/socgen)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_target_property(SOCGEN_INJECT_V_FILES ${IP_LIB} SOCGEN_INJECT_V_FILES)
    if(ARG_INJECT_V_FILES OR SOCGEN_INJECT_V_FILES)
        set(INJECT_V_FILES ${ARG_INJECT_V_FILES} ${SOCGEN_INJECT_V_FILES})
        set(ARG_INJECT_V_FILES --vinject ${INJECT_V_FILES})
    else()
        unset(ARG_INJECT_V_FILES)
        unset(INJECT_V_FILES)
    endif()

    if(ARG_USE_INCLUDE)
        set(ARG_USE_INCLUDE --use-include)
        unset(ADDITIONAL_DEPENDS)
        # Add directories to INCLUDE_DIRECTORIES if --use-include is used
        get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMVERILOG)
        foreach(f ${INJECT_V_FILES})
            get_filename_component(dir ${f} DIRECTORY)
            if(NOT ${dir} IN_LIST INC_DIRS)
                ip_include_directories(${IP_LIB} SYSTEMVERILOG ${dir})
            endif()
        endforeach()
    else()
        set(ADDITIONAL_DEPENDS ${INJECT_V_FILES})
        unset(ARG_USE_INCLUDE)
    endif()

    if(ARG_GEN_DOT)
        set(SOCGEN_DOT_FILES ${OUTDIR}/soc_diagram.dot)
        set_source_files_properties(${SOCGEN_DOT_FILES} PROPERTIES GENERATED TRUE)
        ip_sources(${IP_LIB} GRAPHVIZ  ${SOCGEN_DOT_FILES})
        set(ARG_GEN_DOT --gen-dot)
    else()
        unset(ARG_GEN_DOT)
    endif()

    # Used to overwrite the top level parameters
    set(OVERWRITTEN_PARAMETERS_TARGET "")
    set(OVERWRITTEN_PARAMETERS "")
    if(ARG_PARAMETERS)
        foreach(PARAM ${ARG_PARAMETERS})
            set(OVERWRITTEN_PARAMETERS "${OVERWRITTEN_PARAMETERS}" "-P${PARAM}")
        endforeach()
    endif()

    get_ip_sources(RDL_SOCGEN_GLUE ${IP_LIB} SYSTEMRDL_SOCGEN)
    get_ip_sources(SYSTEMRDL_SOURCES ${IP_LIB} SYSTEMRDL)
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMRDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMRDL)

    if(NOT SYSTEMRDL_SOURCES)
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
    set(__CMD
        ${Python3_EXECUTABLE} -m peakrdl socgen
            --intfs ${RDL_SOCGEN_GLUE}
            -o ${OUTDIR}
            ${SYSTEMRDL_SOURCES}
            ${INCDIRS_ARG}
            ${COMPDEFS_ARG}
            ${ARG_USE_INCLUDE}
            ${ARG_INJECT_V_FILES}
            ${ARG_GEN_DOT}
            ${OVERWRITTEN_PARAMETERS}
        )
    set(__CMD_LF ${__CMD} --list-files)

    # Call peakrdl-socgen with --list-files option to get the list of headers
    execute_process(
        OUTPUT_VARIABLE V_GEN
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${__CMD_LF}
        )
    if(V_GEN)
        string(REPLACE " " ";" V_GEN "${V_GEN}")
        string(REPLACE "\n" "" V_GEN "${V_GEN}")
        list(REMOVE_DUPLICATES V_GEN)
    else()
        string(REPLACE ";" " " __CMD_STR "${__CMD_LF}")
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${IP_LIB},
                output of --list-files option: ${V_GEN} error output: ${ERROR_MSG} \n
                Command Called: \n ${__CMD_STR}")
    endif()

    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)
    ip_sources(${IP_LIB} SYSTEMVERILOG ${V_GEN})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${SOCGEN_DOT_FILES} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SYSTEMRDL_SOURCES} ${ADDITIONAL_DEPENDS}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_socgen
        DEPENDS ${V_GEN} ${SOCGEN_DOT_FILES} ${SOCGEN_DOT_FILES} ${STAMP_FILE}
        )

    add_dependencies(${IP_LIB} ${IP_LIB}_socgen)

endfunction()

include("${CMAKE_CURRENT_LIST_DIR}/common/socgen_props.cmake")
