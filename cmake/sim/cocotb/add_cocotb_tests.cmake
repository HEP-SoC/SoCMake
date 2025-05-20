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
    list(APPEND _msg "------------ Adding cocotb tests for IP_LIB: \"${ALIAS_NAME}\"\n")
    list(APPEND _msg "Added tests:\n")

    enable_testing()
    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        if(SOCMAKE_DONT_ADD_TEST)
            unset(SOCMAKE_DONT_ADD_TEST)
            continue()
        endif()

        if(NOT COCOTB_TESTCASE)

            list(APPEND _msg "   ${COCOTB_MODULE}:         ${COCOTB_DESCRIPTION}\n")
            list(APPEND deps_list ${COCOTB_SIM_BUILD_DEP})
            add_test(
                NAME ${COCOTB_MODULE}
                COMMAND ${COCOTB_SIM_RUN_CMD}
            )
            # Set environment variables for the test (cannot be set as for the custom command)
            set_property(TEST ${COCOTB_MODULE} APPEND PROPERTY ENVIRONMENT PYTHONPATH=${COCOTB_PYTHONPATH})
            set_property(TEST ${COCOTB_MODULE} APPEND PROPERTY ENVIRONMENT MODULE=${COCOTB_MODULE})
            set_property(TEST ${COCOTB_MODULE} APPEND PROPERTY ENVIRONMENT COCOTB_RESULTS_FILE=${PROJECT_BINARY_DIR}/results.xml)
            # Simulators (e.g., icarus, xcelium) always returns 0 (pass) so check the output to detect a failure
            # We only check if test passed or not checking cocotb summary header at the end
            set_property(TEST ${COCOTB_MODULE} PROPERTY
                PASS_REGULAR_EXPRESSION "[^a-z]FAIL=0"
            )

        else() # COCOTB_TESTCASE

            list(APPEND deps_list ${COCOTB_SIM_BUILD_DEP})

            foreach(i RANGE 1 ${COCOTB_TESTCASE})

                # Add leading zeros based on the value of the loop variable
                if(${i} LESS 10)
                    set(test_num "00${i}")
                elseif(${i} LESS 100)
                    set(test_num "0${i}")
                endif()

                list(APPEND _msg "   ${COCOTB_MODULE}:         ${COCOTB_DESCRIPTION} - test ${test_num}\n")

                add_test(
                    NAME ${COCOTB_MODULE}_test_${test_num}
                    COMMAND ${COCOTB_SIM_RUN_CMD}
                )
                # Set environment variables for the test (cannot be set as for the custom command)
                if(COCOTB_PYTHONPATH)
                    set_property(TEST ${COCOTB_MODULE}_test_${test_num} APPEND PROPERTY ENVIRONMENT PYTHONPATH=${COCOTB_PYTHONPATH})
                endif()
                set_property(TEST ${COCOTB_MODULE}_test_${test_num} APPEND PROPERTY ENVIRONMENT MODULE=${COCOTB_MODULE})
                set_property(TEST ${COCOTB_MODULE}_test_${test_num} APPEND PROPERTY ENVIRONMENT COCOTB_RESULTS_FILE=${PROJECT_BINARY_DIR}/test_${test_num}/results.xml)
                set_property(TEST ${COCOTB_MODULE}_test_${test_num} APPEND PROPERTY ENVIRONMENT TESTCASE=${COCOTB_MODULE}_test_${test_num})
                # Simulators (e.g., icarus, xcelium) always returns 0 (pass) so check the output to detect a failure
                # We only check if test passed or not checking cocotb summary header at the end
                set_property(TEST ${COCOTB_MODULE}_test_${test_num} PROPERTY
                    PASS_REGULAR_EXPRESSION "[^a-z]FAIL=0"
                )

            endforeach()
        endif() # COCOTB_TESTCASE
        unset(COCOTB_TESTCASE)
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${IP_LIB} ${deps_list}
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
