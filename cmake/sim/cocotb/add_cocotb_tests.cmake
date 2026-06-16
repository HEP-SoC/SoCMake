#[[[ @module cocotb_tests
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# This function scans a given directory for cocotb test subdirectories and registers each as a CTest, with support for both simple and multi-testcase cocotb test configurations.
# Multi-testcase tests are auto-numbered into single CTest and a ``check`` target is created to run all the different tests.
#
# Each test subdirectory's ``CMakeLists.txt`` is expected to set the following variables in ``PARENT_SCOPE`` to register a test:
#
# - ``COCOTB_MODULE`` (required): name of the test, used as the CTest name.
# - ``COCOTB_SIM_RUN_CMD`` (required): command used to run the simulation.
# - ``COCOTB_SIM_BUILD_DEP`` (required): build target(s) the simulation run depends on.
# - ``COCOTB_DESCRIPTION`` (optional): human readable description, shown in the summary message.
# - ``COCOTB_PYTHONPATH`` (optional): ``PYTHONPATH`` environment variable for the test.
# - ``COCOTB_TESTCASE`` (optional): number of test cases to register (from 1 to N). If unset, a single CTest is registered.
#
# If a subdirectory does not set ``COCOTB_MODULE``, it is silently skipped (no test registered for it).
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog files.
# :type IP_LIB: string
# :param DIRECTORY: Path to the directory containing the cocotb test subdirectories to scan. Subdirectories prefixed with ``_`` are excluded.
# :type DIRECTORY: path string
#]]
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
        # Reset the variables expected to be set by the test subdirectory's CMakeLists.txt,
        # so that a subdirectory which sets none of them is correctly detected as "no test to add"
        # instead of inheriting stale values from a previous loop iteration.
        unset(COCOTB_MODULE)
        unset(COCOTB_DESCRIPTION)
        unset(COCOTB_SIM_RUN_CMD)
        unset(COCOTB_SIM_BUILD_DEP)
        unset(COCOTB_PYTHONPATH)
        unset(COCOTB_TESTCASE)

        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")

        if(NOT COCOTB_MODULE)
            socmake_message(STATUS "add_cocotb_tests: \"${test}\" did not set COCOTB_MODULE, skipping (no test registered)")
            continue()
        endif()

        if(NOT COCOTB_SIM_RUN_CMD)
            socmake_message(WARNING "add_cocotb_tests: \"${test}\" set COCOTB_MODULE but not COCOTB_SIM_RUN_CMD, skipping")
            continue()
        endif()

        if(NOT COCOTB_SIM_BUILD_DEP)
            socmake_message(WARNING "add_cocotb_tests: \"${test}\" set COCOTB_MODULE but not COCOTB_SIM_BUILD_DEP, skipping")
            continue()
        endif()

        socmake_message(STATUS "add_cocotb_tests: registering test(s) for module \"${COCOTB_MODULE}\" from \"${test}\"")

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
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${IP_LIB} ${deps_list}
    )

    socmake_message(STATUS "test_list: ${test_list}")

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "    make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "   make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()
