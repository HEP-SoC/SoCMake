function(add_cocotb_tests IP_LIB DIRECTORY)
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    set(EXCLUDE_PATTERNS "_")
    SUBDIRLIST_EXCLUDE(TEST_SUBDIRS ${DIRECTORY} "${EXCLUDE_PATTERNS}")

    # Assume the IP library is the latest one provided if full name is not given
    alias_dereference(IP_LIB ${IP_LIB})

    unset(msg)
    list(APPEND _msg "-------------------------------------------------------------------------\n")
    string(REPLACE "__" "::" ALIAS_NAME ${IP_LIB})
    list(APPEND _msg "------------ Adding tests for IP_LIB: \"${ALIAS_NAME}\"\n")
    list(APPEND _msg "Added tests:\n")

    enable_testing()
    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        if(SOCMAKE_DONT_ADD_TEST)
            unset(SOCMAKE_DONT_ADD_TEST)
            continue()
        endif()
        foreach(cocotb_test ${COCOTB_TB_NAME})
            list(APPEND _msg "   ${cocotb_test}:         ${${cocotb_test}_DESCRIPTION}\n")
            list(APPEND test_list ${cocotb_test})
            string(TOUPPER ${cocotb_test} COCOTB_RUN_PROP)
            get_target_property(COCOTB_RUN_SIM_CMD ${IP_LIB} COCOTB_${COCOTB_RUN_PROP})
            # get_target_property(COCOTB_IVERILOG_TEST_ENV ${IP_LIB} COCOTB_IVERILOG_${COCOTB_TEST_PROP}_ENV)
            message(STATUS "COCOTB_RUN_SIM_CMD: ${COCOTB_RUN_SIM_CMD}")
            add_test(
                NAME ${cocotb_test}
                COMMAND ${COCOTB_RUN_SIM_CMD}
            )
            # # The ENVIRONMENT property expect the variables in a specific format so its safer to
            # # set them one by one and let the function do the correct formating
            # foreach(prop ${COCOTB_IVERILOG_TEST_ENV})
            #     set_property(TEST ${cocotb_test} APPEND PROPERTY ENVIRONMENT ${prop})
            # endforeach()
            # simulators (e.g., icarus, xcelium) always returns 0 (pass) so check the output to detect a failure
            # We only check if test passed or not checking cocotb summary header at the end
            set_property(TEST ${cocotb_test} PROPERTY
                PASS_REGULAR_EXPRESSION "[^a-z]FAIL=0"
            )
        endforeach()
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${IP_LIB}
    )

    message(STATUS "test_list: ${test_list}")

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "    make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "   make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()
