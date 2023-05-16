function(uart_programmer DIRECTORY BAUDRATE DEV)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
     
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/subdirectory_search.cmake")
    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})
    
    set(UART_PROGRAMMER ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/uart_programmer.py)

    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        foreach(fw_prj ${FW_PROJECT_NAME})
            get_target_property(HEX_FILE ${fw_prj} HEX_32bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_32bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_32bit_FILE)

            add_custom_target(program_${fw_prj}
                COMMAND python3 ${UART_PROGRAMMER}
                --text-hex ${HEX_TEXT_FILE}
                --data-hex ${HEX_DATA_FILE}
                --baudrate ${BAUDRATE}
                --dev ${DEV}
                DEPENDS ${fw_prj}
                )
        endforeach()
    endforeach()
endfunction()


