function(copy_rtl_files IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;TOP_MODULE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Check if a top module is provided. In this case only the modules in its hierarchy are kept
    if(ARG_TOP_MODULE)
        set(TOP_MODULE --top-module ${ARG_TOP_MODULE})
    endif()

    # Get the list of RTL sources
    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    # Create a list to hold the RTL files as arguments for the Python script
    set(RTL_FILES_ARGS)
    # Add each RTL file to the list of arguments
    foreach(file ${RTL_SOURCES})
        list(APPEND RTL_FILES_ARGS ${file})
    endforeach()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/copy_rtl_files.py
        ${TOP_MODULE} --outdir ${OUTDIR} ${RTL_FILES_ARGS}
    )

    # Call the Python script with the output directory and the RTL files
    set(STAMP_FILE "${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMENT "Copying RTL files to ${OUTDIR}"
        VERBATIM
    )

    # Create a target to run the custom command
    add_custom_target(
        ${IP_LIB}_copy_rtl
        ALL DEPENDS ${IP_LIB} ${STAMP_FILE}
    )
endfunction()
