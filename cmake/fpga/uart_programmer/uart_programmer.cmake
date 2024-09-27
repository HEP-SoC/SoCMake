function(format_string OUTPUT_VAR input_string replacements)
    # Split the input string into separate lines.
    string(REPLACE "\n" ";" lines "${input_string}")

    # Split the replacement characters into a list.
    string(REPLACE ";" ";" replacement_list "${replacements}")

    set(formatted_string "")   # To store the final formatted result
    set(max_lengths "")        # To store the maximum length of each part before space

    # Step 1: Calculate maximum lengths for the sections before each space
    message("foreach(line IN LISTS lines): ${input_string}")
    foreach(line IN LISTS lines)
        message("${line}")
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
    foreach(line IN LISTS lines)
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

            # Add the replacement string if available
            list(LENGTH replacement_list replacement_count)
            if(${index} LESS replacement_count)
                list(GET replacement_list ${index} replacement_char)
                set(formatted_line "${formatted_line}${replacement_char}")
            endif()

            math(EXPR index "${index} + 1")
        endforeach()

        # Add the formatted line to the final formatted string
        string(APPEND formatted_string "${formatted_line}\n")
    endforeach()

    # Step 3: Return the formatted string
    set(${OUTPUT_VAR} "${formatted_string}" PARENT_SCOPE)
endfunction()


function(uart_programmer DIRECTORY BAUDRATE DEV)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")
    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})

    find_python3()
    set(UART_PROGRAMMER ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/uart_programmer.py)

    unset(_msg)
    list(APPEND _msg "-------------------------------------------------------------------------\n")
    string(REPLACE "__" "::" ALIAS_NAME ${SOC_NAME})
    list(APPEND _msg "Adding tests for SoC:\n")
    list(APPEND _msg "  ${ALIAS_NAME}\n")
    list(APPEND _msg "Added tests:\n")

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
            get_target_property(HEX_FILE ${fw_prj} HEX_32bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_32bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_32bit_FILE)

            add_custom_target(program_${fw_prj}
                COMMAND ${Python3_EXECUTABLE} ${UART_PROGRAMMER}
                --text-hex ${HEX_TEXT_FILE}
                --data-hex ${HEX_DATA_FILE}
                --baudrate ${BAUDRATE}
                --dev ${DEV}
                DEPENDS ${fw_prj}
                )
        endforeach()
    endforeach()

    format_string(formatted_test_msg "${_test_msg}" "    ;  ")

    message("Non-formatted string:\n" ${_test_msg})
    message("Formatted string:\n" ${formatted_test_msg})

    list(APPEND _msg "${formatted_test_msg}")

    list(APPEND _msg "To run any of the added tests on the FPGA:\n")
    list(APPEND _msg "   make program_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)

endfunction()


