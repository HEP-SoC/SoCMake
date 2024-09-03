function(copy_rtl_files IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;TOP_MODULE;SKIPLIST_FILE" "" ${ARGN})
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

    # Get the list of RTL sources
    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})
    get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
    foreach(_i ${RTL_INCDIRS})
        set(INCDIR_ARG ${INCDIR_ARG} --include ${_i})
    endforeach()

    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/copy_rtl_files.py
        ${TOP_MODULE_ARG} ${SKIPLIST_ARG}
        --deps_dir ${FETCHCONTENT_BASE_DIR}
        ${INCDIR_ARG}
        --outdir ${OUTDIR}
        ${RTL_SOURCES}
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
