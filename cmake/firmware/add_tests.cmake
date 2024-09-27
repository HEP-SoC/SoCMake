function(format_string OUTPUT_VAR input_list replacements)
    # Split the replacement characters into a list.
    string(REPLACE ";" ";" replacement_list "${replacements}")

    set(formatted_string "")   # To store the final formatted result
    set(max_lengths "")        # To store the maximum length of each part before spaces

    # Step 1: Calculate maximum lengths for the sections before each space
    foreach(line IN LISTS input_list)
        string(REPLACE " " ";" split_line "${line}")
        set(index 0)
        foreach(section IN LISTS split_line)
            string(LENGTH "${section}" section_length)

            # Expand max_lengths if it is the first pass
            list(LENGTH max_lengths list_size)
            if(list_size LESS_EQUAL index)
                list(APPEND max_lengths 0)
            endif()

            # Update max length for each column section
            list(GET max_lengths ${index} current_max_length)
            if(section_length GREATER current_max_length)
                list(REMOVE_AT max_lengths ${index})
                list(INSERT max_lengths ${index} ${section_length})
            endif()

            math(EXPR index "${index} + 1")
        endforeach()
    endforeach()

    # Step 2: Format each line based on the calculated max lengths
    foreach(line IN LISTS input_list)
        string(REPLACE " " ";" split_line "${line}")

        set(formatted_line "")
        set(index 0)
        foreach(section IN LISTS split_line)
            # Get the length of the section
            string(LENGTH "${section}" section_length)

            # Get the max length for this section
            list(GET max_lengths ${index} max_length)

            # Pad the section with spaces to match the maximum length
            math(EXPR padding_length "${max_length} - ${section_length}")
            string(REPEAT " " ${padding_length} padding)

            # Append the section to the formatted line
            set(formatted_line "${formatted_line}${section}${padding}")

            # Add the replacement string if available, otherwise keep original space
            list(LENGTH replacement_list replacement_count)
            if(${index} LESS replacement_count)
                list(GET replacement_list ${index} replacement_char)
                set(formatted_line "${formatted_line}${replacement_char}")
            else()
                # Add original space back if no replacement is available
                set(formatted_line "${formatted_line} ")
            endif()

            math(EXPR index "${index} + 1")
        endforeach()

        # Add the formatted line to the final formatted string
        string(APPEND formatted_string "${formatted_line}\n")
    endforeach()

    # Step 3: Return the formatted string
    set(${OUTPUT_VAR} "${formatted_string}" PARENT_SCOPE)
endfunction()

function(add_tests EXECUTABLE DIRECTORY)
    cmake_parse_arguments(ARG "USE_PLUSARGS" "WIDTH" "ARGS;DEPS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/colours.cmake")
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
        list(APPEND _test_msg " ${fw_prj}: ${${fw_prj}_DESCRIPTION}\n")
            list(APPEND test_list ${fw_prj})
            get_target_property(HEX_FILE ${fw_prj} HEX_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_${ARG_WIDTH}bit_FILE)
            add_test(
                NAME ${fw_prj}
                COMMAND ./${EXECUTABLE}
                    ${PREFIX}firmware=${HEX_FILE}
                    ${PREFIX}firmware_text=${HEX_TEXT_FILE}
                    ${PREFIX}firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
            )

            add_custom_target(run_${fw_prj}
                COMMAND ./${EXECUTABLE}
                    ${PREFIX}firmware=${HEX_FILE}
                    ${PREFIX}firmware_text=${HEX_TEXT_FILE}
                    ${PREFIX}firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
                DEPENDS ${EXECUTABLE} ${fw_prj} ${ARG_DEPS}
            )
        endforeach()
    endforeach()

    include(ProcessorCount)
    ProcessorCount(NPROC)
    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} -j${NPROC}
        DEPENDS ${test_list} ${EXECUTABLE}
    )

    # set(formatted_test_msg "")
    format_string(formatted_test_msg ${_test_msg} "    ;  ")
    # string(REPLACE ";" "" formatted_test_msg "${formatted_test_msg}")

    message("Non-formatted string:\n${_test_msg}")
    message("Formatted string:\n${formatted_test_msg}")

    list(APPEND _msg "${formatted_test_msg}")

    list(APPEND _msg "\nTo run ctest on all of the tests run:\n")
    list(APPEND _msg "    make check\n")
    list(APPEND _msg "To run any of the added tests execute:\n")
    list(APPEND _msg "   make run_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)
endfunction()

