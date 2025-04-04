# Iterates through the DIRECTORY sub-directories and create targets
# to start uart transactions for each test.
function(uart_programmer DIRECTORY BAUDRATE DEV)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/format_string_spacing.cmake")
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
            list(APPEND _test_msg " ${fw_prj}: ${${fw_prj}_DESCRIPTION}")
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

    format_string_spacing(formatted_test_msg "${_test_msg}" "  ;  ")

    list(APPEND _msg "${formatted_test_msg}")

    list(APPEND _msg "To run any of the added tests on the FPGA:\n")
    list(APPEND _msg "  make program_<test_name>\n")
    list(APPEND _msg "-------------------------------------------------------------------------")
    string(REPLACE ";" "" _msg "${_msg}")
    msg("${_msg}" Blue)

endfunction()


