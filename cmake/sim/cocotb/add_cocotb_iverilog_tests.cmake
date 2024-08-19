function(add_cocotb_iverilog_tests IP_LIB DIRECTORY)
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})

    # Assume the IP library is the latest one provided if full name is not given
    ip_assume_last(IP_LIB ${IP_LIB})

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
            string(TOUPPER ${cocotb_test} COCOTB_TEST_PROP)
            get_target_property(COCOTB_IVERILOG_TEST_CMD ${IP_LIB} COCOTB_IVERILOG_${COCOTB_TEST_PROP}_CMD)
            get_target_property(COCOTB_IVERILOG_TEST_ENV ${IP_LIB} COCOTB_IVERILOG_${COCOTB_TEST_PROP}_ENV)
            add_test(
                NAME ${cocotb_test}
                COMMAND ${COCOTB_IVERILOG_TEST_CMD}
            )
            # The ENVIRONMENT property expect the variables in a specific format so its safer to
            # set them one by one and let the function do the correct formating
            foreach(prop ${COCOTB_IVERILOG_TEST_ENV})
                set_property(TEST ${cocotb_test} APPEND PROPERTY ENVIRONMENT ${prop})
            endforeach()
            # vvp (iverilog) always returns 0 (pass) so check the output to detect a failure
            set_property(TEST ${cocotb_test} PROPERTY
                FAIL_REGULAR_EXPRESSION "[^a-z]FAIL"
            )
        endforeach()
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${test_list} ${IP_LIB}
    )

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "    make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "   make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()

