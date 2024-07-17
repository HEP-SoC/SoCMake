function(copy_ip_sources IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;FLOW;TOP" "" ${ARGN})
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

    get_ip_rtl_sources(RTL_SOURCES ${IP_LIB})

    # Add extra files depending on the flow (i.e., SIM, ASIC, FPGA)
    if(${ARG_FLOW} STREQUAL "SIM")
        get_ip_sim_only_sources(EXTRA_RTL_SOURCES ${IP_LIB})
    elseif(${ARG_FLOW} STREQUAL "FPGA")
        get_ip_fpga_only_sources(EXTRA_RTL_SOURCES ${IP_LIB})
    endif()
    # The extra sources are usually low level cells/modules so prepend them
    list(PREPEND RTL_SOURCES ${EXTRA_RTL_SOURCES})

    # Check it a top is provided. In this case only the modules in its hierarchy are kept
    if(ARG_TOP)
        set(TOP --top ${ARG_TOP})
    endif()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/copy_ip_sources.py
        ${ARG_TOP} --path ${OUTDIR} ${RTL_SOURCES}
    )

    set(__CMD_LF ${__CMD} --list-files)

    # Call with --list-files option to get the list of generated files
    execute_process(
        OUTPUT_VARIABLE FILES_GEN
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${__CMD_LF}
    )
    # Check the files are generated
    if(FILES_GEN)
        string(REPLACE " " ";" FILES_GEN "${FILES_GEN}")
        string(REPLACE "\n" "" FILES_GEN "${FILES_GEN}")
        list(REMOVE_DUPLICATES FILES_GEN)
    else()
        string(REPLACE ";" " " __CMD_STR "${__CMD_LF}")
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${IP_LIB},
                output of --list-files option: ${FILES_GEN} error output: ${ERROR_MSG} \n
                Command Called: \n ${__CMD_STR}")
    endif()

    set(STAMP_FILE "${CMAKE_BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${FILES_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RTL_SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_copy_ip_sources
        DEPENDS ${FILES_GEN} ${STAMP_FILE}
    )

    # add_dependencies(${IP_LIB} ${IP_LIB}_socgen)

endfunction()