# Iterates through the DIRECTORY sub-directories and create targets
# to start simulating each test.
function(add_tests EXECUTABLE DIRECTORY)
    cmake_parse_arguments(ARG "USE_PLUSARGS" "WIDTH" "ARGS;DEPS" ${ARGN})
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
        set(PREFIX +)
    else()
        set(PREFIX --)
    endif()

    unset(_msg)
    list(APPEND _msg "-------------------------------------------------------------------------\n")
    string(REPLACE "__" "::" ALIAS_NAME ${SOC_NAME})
    list(APPEND _msg "Adding tests for SoC:\n")
    list(APPEND _msg "  ${ALIAS_NAME}, tb executable: ${EXECUTABLE}\n")
    list(APPEND _msg "Added tests:\n")

    enable_testing()
    unset(_test_msg)
    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        if(SOCMAKE_DONT_ADD_TEST)
            unset(SOCMAKE_DONT_ADD_TEST)
            continue()
        endif()
        foreach(fw_prj ${FW_PROJECT_NAME})
        list(APPEND _test_msg " ${fw_prj}: ${${fw_prj}_DESCRIPTION}")
            list(APPEND test_list ${fw_prj})
            get_target_property(HEX_FILE ${fw_prj} HEX_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_${ARG_WIDTH}bit_FILE)
            add_test(
                NAME ${fw_prj}
                COMMAND ${EXECUTABLE}
                    ${PREFIX}firmware=${HEX_FILE}
                    ${PREFIX}firmware_text=${HEX_TEXT_FILE}
                    ${PREFIX}firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
                WORKING_DIRECTORY ${test}_test
            )

            add_custom_target(run_${fw_prj}
                COMMAND ${EXECUTABLE}
                    ${PREFIX}firmware=${HEX_FILE}
                    ${PREFIX}firmware_text=${HEX_TEXT_FILE}
                    ${PREFIX}firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
                DEPENDS ${fw_prj} ${ARG_DEPS}
            )
            # Add dependency if the EXECUTABLE is a target created by add_executable
            if(TARGET ${EXECUTABLE})
                add_dependencies(run_${fw_prj} ${EXECUTABLE})
            endif()
        endforeach()
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${test_list}
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

