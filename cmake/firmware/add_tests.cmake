# Iterates through the DIRECTORY sub-directories and create targets
# to start simulating each test.
function(add_tests EXECUTABLE DIRECTORY)
    cmake_parse_arguments(ARG "USE_PLUSARGS" "NPROC;WIDTH;TEST_PREFIX;TESTCASE_PARAM" "TESTCASE;ARGS;DEPS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/colours.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/format_string_spacing.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/fw_utils.cmake")
    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})

    if(NOT ARG_WIDTH)
        set(ARG_WIDTH 32)
    endif()

    if(ARG_USE_PLUSARGS)
        set(PREFIX_ARG +)
    else()
        set(PREFIX_ARG --)
    endif()

    if(NOT ARG_TESTCASE)
        set(TESTCASE_LIST "UNKNOWN")
    else()
        set(TESTCASE_LIST ${ARG_TESTCASE})
    endif()

    # Prefi added to all the test names
    if(ARG_TEST_PREFIX)
        set(TEST_PREFIX ${ARG_TEST_PREFIX}_)
    endif()

    unset(_msg)
    list(APPEND _msg "-------------------------------------------------------------------------\n")
    string(REPLACE "__" "::" ALIAS_NAME ${SOC_NAME})
    list(APPEND _msg "Adding tests for SoC:\n")
    list(APPEND _msg "  ${ALIAS_NAME}, tb executable: ${EXECUTABLE}\n")
    list(APPEND _msg "Added tests:\n")

    enable_testing()
    unset(_test_msg)
    # Add the tests for all the TESTCASES
    foreach(test ${TEST_SUBDIRS})
        # Add each test subdirectoy
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        if(SOCMAKE_DONT_ADD_TEST)
            # Skip the test if SOCMAKE_DONT_ADD_TEST is set by the project
            unset(SOCMAKE_DONT_ADD_TEST)
            continue()
        endif()
        # Iterate over the testcases and add each test
        foreach(testcase ${TESTCASE_LIST})
            foreach(fw_prj ${FW_PROJECT_NAME})
                # TESTCASE argument can be used to generate multiple tests with different names
                if(NOT ${testcase} STREQUAL "UNKNOWN")
                    set(fw_prj_name ${TEST_PREFIX}${fw_prj}_${testcase})
                else()
                    set(fw_prj_name ${TEST_PREFIX}${fw_prj})
                endif()
                # Pass the testcase value as a parameter if TEST_CASE_PARAM is given
                if(ARG_TESTCASE_PARAM)
                    set(TESTCASE_PARAM ${PREFIX_ARG}${ARG_TESTCASE_PARAM}=${testcase})
                endif()
                list(APPEND _test_msg " ${fw_prj_name}: ${${fw_prj}_DESCRIPTION}")
                list(APPEND test_list ${fw_prj})
                get_target_property(HEX_FILE ${fw_prj} HEX_${ARG_WIDTH}bit_FILE)
                get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_${ARG_WIDTH}bit_FILE)
                get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_${ARG_WIDTH}bit_FILE)
                get_target_property(SREC_TEXT_FILE ${fw_prj} SREC_TEXT_${ARG_WIDTH}bit_FILE)
                get_target_property(SREC_DATA_FILE ${fw_prj} SREC_DATA_${ARG_WIDTH}bit_FILE)
                # Create teh test working directory if it does not exists
                set(test_working_dir ${test}_test/${fw_prj_name}_test)
                execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${test_working_dir})
                add_test(
                    NAME ${fw_prj_name}
                    COMMAND ${EXECUTABLE}
                        ${PREFIX_ARG}firmware=${HEX_FILE}
                        ${PREFIX_ARG}firmware_text=${HEX_TEXT_FILE}
                        ${PREFIX_ARG}firmware_data=${HEX_DATA_FILE}
                        ${PREFIX_ARG}firmware_text_srec=${SREC_TEXT_FILE}
                        ${PREFIX_ARG}firmware_data_srec=${SREC_DATA_FILE}
                        ${TESTCASE_PARAM}
                        ${ARG_ARGS}
                    WORKING_DIRECTORY ${test_working_dir}
                )

                add_custom_target(run_${fw_prj_name}
                    COMMAND ${EXECUTABLE}
                        ${PREFIX_ARG}firmware=${HEX_FILE}
                        ${PREFIX_ARG}firmware_text=${HEX_TEXT_FILE}
                        ${PREFIX_ARG}firmware_data=${HEX_DATA_FILE}
                        ${PREFIX_ARG}firmware_text_srec=${SREC_TEXT_FILE}
                        ${PREFIX_ARG}firmware_data_srec=${SREC_DATA_FILE}
                        ${TESTCASE_PARAM}
                        ${ARG_ARGS}
                    DEPENDS ${fw_prj} ${ARG_DEPS} ${test_working_dir}
                )
                # Add additional clean files to project
                set_property(
                    TARGET run_${fw_prj_name}
                    APPEND
                    PROPERTY ADDITIONAL_CLEAN_FILES
                    ${test_working_dir}
                )
                # Add dependency if the EXECUTABLE is a target created by add_executable
                if(TARGET ${EXECUTABLE})
                    add_dependencies(run_${fw_prj_name} ${EXECUTABLE})
                endif()
            endforeach() # FW_PROJECT_NAME
        endforeach() # TESTCASE_LIST
    endforeach() # TEST_SUBDIRS

    include(ProcessorCount)
    if(NOT ARG_NPROC)
        ProcessorCount(NPROC)
    else()
        set(NPROC ${ARG_NPROC})
    endif()
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${test_list} ${ARG_DEPS}
    )
    # Add dependency if the EXECUTABLE is a target created by add_executable
    if(TARGET ${EXECUTABLE})
        add_dependencies(check ${EXECUTABLE})
    endif()

    format_string_spacing(formatted_test_msg "${_test_msg}" "  ;  ")

    list(APPEND _msg "${formatted_test_msg}")

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "  make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "  make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()

