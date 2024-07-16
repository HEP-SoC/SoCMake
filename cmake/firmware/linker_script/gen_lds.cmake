#[[[
# This function generates linker script (LDS) file for the specified IP library.
#
# :param IP_LIB: The name of the IP library target.
# :type IP_LIB: str
#]]
function(gen_lds IP_LIB)
    # Parse the arguments passed to the function
    cmake_parse_arguments(ARG "NODEBUG" "OUTDIR" "PARAMETERS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Include necessary CMake files
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../fw_utils.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    # Define the path to the linker script generation tool
    set(LDS_GEN_TOOL "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/src/gen_linker_script.py")

    # Set the IP library to the last specified
    ip_assume_last(IP_LIB ${IP_LIB})
    # Get the binary directory of the IP library
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Set the output directory for the linker script
    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/lds)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Set the debug flag if NODEBUG is not specified
    if(ARG_NODEBUG)
        set(ARG_NODEBUG)
    else()
        set(ARG_NODEBUG --debug)
    endif()

    # Initialize string to store overwritten parameters
    set(OVERWRITTEN_PARAMETERS "")
    # Process any specified parameters to overwrite
    if(ARG_PARAMETERS)
        set(OVERWRITTEN_PARAMETERS "-p")
        foreach(PARAM ${ARG_PARAMETERS})
            set(OVERWRITTEN_PARAMETERS "${OVERWRITTEN_PARAMETERS}" "${PARAM}")
        endforeach()
    endif()

    # Create the output directory if it does not exist
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    # Get the system RDL files for the IP library
    get_ip_sources(RDL_FILES ${IP_LIB} SYSTEMRDL)

    # Check if system RDL files exist
    if(NOT RDL_FILES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    # Set the path to the generated linker script file
    set(LDS_FILE "${OUTDIR}/${IP_LIB}.lds")

    # Mark the linker script file as generated
    set_source_files_properties(${LDS_FILE} PROPERTIES GENERATED TRUE)
    # Set linker script file as IP library source
    ip_sources(${IP_LIB} LINKER_SCRIPT ${LDS_FILE})

    # Set the stamp file path
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    # Add custom command to generate linker script
    add_custom_command(
        OUTPUT ${LDS_FILE} ${STAMP_FILE}
        COMMAND ${Python3_EXECUTABLE} ${LDS_GEN_TOOL}
            --rdlfiles ${RDL_FILES}
            --outfile ${LDS_FILE}
            ${ARG_NODEBUG}
            ${OVERWRITTEN_PARAMETERS}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    # Add custom target for generating linker script
    add_custom_target(
        ${IP_LIB}_lds
        DEPENDS ${RDL_FILES} ${STAMP_FILE}
        )

    # Add dependency on the custom target for the IP library
    add_dependencies(${IP_LIB} ${IP_LIB}_lds)
endfunction()
