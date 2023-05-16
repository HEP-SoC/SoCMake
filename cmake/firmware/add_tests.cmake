function(add_tests EXECUTABLE DIRECTORY)
    cmake_parse_arguments(ARG "" "" "ARGS;DEPS" ${ARGN})
     
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/subdirectory_search.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/fw_utils.cmake")
    SUBDIRLIST(TEST_SUBDIRS ${DIRECTORY})
    
    enable_testing()
    foreach(test ${TEST_SUBDIRS})
        add_subdirectory("${DIRECTORY}/${test}" "${test}_test")
        foreach(fw_prj ${FW_PROJECT_NAME})
            get_target_property(HEX_FILE ${fw_prj} HEX_32bit_FILE)
            get_target_property(HEX_TEXT_FILE ${fw_prj} HEX_TEXT_32bit_FILE)
            get_target_property(HEX_DATA_FILE ${fw_prj} HEX_DATA_32bit_FILE)
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

