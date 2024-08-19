function(add_cocotb_iverilog_tests IP DIRECTORY)
    # cmake_parse_arguments(ARG "" "WIDTH" "ARGS;DEPS" ${ARGN})
    # if(ARG_UNPARSED_ARGUMENTS)
    #     message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    # endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})

    unset(msg)
    list(APPEND _msg "-------------------------------------------------------------------------\n")
    string(REPLACE "__" "::" ALIAS_NAME ${IP})
    list(APPEND _msg "------------ Adding tests for IP: \"${ALIAS_NAME}\"\n")
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
            get_target_property(COCOTB_IVERILOG_TEST_CMD ${IP} COCOTB_IVERILOG_${COCOTB_TEST_PROP})
            add_test(
                NAME ${cocotb_test}
                COMMAND ${COCOTB_IVERILOG_TEST_CMD}
                )
        endforeach()
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${test_list} ${IP}
        )

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "    make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "   make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()
