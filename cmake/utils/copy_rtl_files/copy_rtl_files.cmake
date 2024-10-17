function(copy_rtl_files IP_LIB)
    cmake_parse_arguments(ARG "SYNTHESIS" "OUTDIR;TOP_MODULE;SKIPLIST_FILE" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # Check if a top module is provided. In this case only the modules in its hierarchy are kept
    if(ARG_TOP_MODULE)
        set(TOP_MODULE_ARG --top-module ${ARG_TOP_MODULE})
    endif()

    if(ARG_SKIPLIST_FILE)
        set(SKIPLIST_ARG --skiplist ${ARG_SKIPLIST_FILE})
    endif()

    if(ARG_SYNTHESIS)
        set(SYNTHESIS_ARG --synthesis)
    endif()

    # Get the list of RTL sources
    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    foreach(_i ${RTL_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} --include ${_i})
    endforeach()

    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/copy_rtl_files.py
        ${TOP_MODULE_ARG} ${SKIPLIST_ARG} ${SYNTHESIS_ARG}
        --deps_dir ${FETCHCONTENT_BASE_DIR}
        ${INCDIR_ARG}
        --outdir ${OUTDIR}
        ${RTL_SOURCES}
    )

    set(__CMD_LF ${__CMD} --list_files)

    # Call the script with --list-files option to get the list of files
    execute_process(
        OUTPUT_VARIABLE COPIED_RTL_SOURCES
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${__CMD_LF}
    )

    if(COPIED_RTL_SOURCES)
        string(REPLACE " " ";" COPIED_RTL_SOURCES "${COPIED_RTL_SOURCES}")
        string(REPLACE "\n" "" COPIED_RTL_SOURCES "${COPIED_RTL_SOURCES}")
        message("COPY LIST FILES: ${COPIED_RTL_SOURCES}")
    else()
        string(REPLACE ";" " " __CMD_STR "${__CMD_LF}")
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${IP_LIB},
                output of --list-files option: ${COPIED_RTL_SOURCES} error output: ${ERROR_MSG} \n
                Command Called: \n ${__CMD_STR}")
    endif()

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

    # Set the configuration variable for the template
    get_target_property(CONF_PROJECT_NAME ${IP_LIB} IP_NAME)
    set(CONF_PROJECT_NAME ${CONF_PROJECT_NAME}_COPIED)
    get_target_property(CONF_PROJECT_VENDOR ${IP_LIB} VENDOR)
    get_target_property(CONF_PROJECT_LIBRARY ${IP_LIB} LIBRARY)
    get_target_property(CONF_PROJECT_VERSION ${IP_LIB} VERSION)
    set(CONF_PROJECT_LANGUAGES NONE)
    set(CONF_COPIED_RTL_SOURCES ${COPIED_RTL_SOURCES})
    # Generate the CMakeLists.txt file inside OUTDIR to enable simple re-integration with cmake
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CMakeLists.txt.in ${OUTDIR}/CMakeLists.txt @ONLY)

endfunction()
