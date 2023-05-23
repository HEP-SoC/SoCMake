function(add_tests EXECUTABLE DIRECTORY)
    cmake_parse_arguments(ARG "" "WIDTH" "ARGS;DEPS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
     
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/fw_utils.cmake")
    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})

    if(NOT ARG_WIDTH)
        set(ARG_WIDTH 32)
    endif()
    
    enable_testing()
    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        foreach(fw_prj ${FW_PROJECT_NAME})
            get_target_property(HEX_FILE ${fw_prj} HEX_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_${ARG_WIDTH}bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_${ARG_WIDTH}bit_FILE)
            add_test(
                NAME ${fw_prj}
                COMMAND ./${EXECUTABLE} 
                    +firmware=${HEX_FILE} 
                    +firmware_text=${HEX_TEXT_FILE}
                    +firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
                )

            add_custom_target(run_${fw_prj}
                COMMAND ./${EXECUTABLE} 
                    +firmware=${HEX_FILE} 
                    +firmware_text=${HEX_TEXT_FILE}
                    +firmware_data=${HEX_DATA_FILE}
                    ${ARG_ARGS}
                DEPENDS ${EXECUTABLE} ${fw_prj} ${ARG_DEPS}
                )
        endforeach()
    endforeach()
endfunction()

