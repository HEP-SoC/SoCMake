function(add_test_makefile_rule_match_patterns TARGET)
    if(ARGC LESS 2)
        message(FATAL_ERROR "Provide search patterns as arguments to ${CMAKE_CURRENT_FUNCTION}")
    endif()

    set(SEARCH_PATTERNS "")
    foreach(pattern ${ARGN})
        set(SEARCH_PATTERNS "${SEARCH_PATTERNS} \"${pattern}\"")
    endforeach()

    include(CTest)
    enable_testing()

    get_target_property(BINARY_DIR ${TARGET} BINARY_DIR)

    set(MAKEFILE ${BINARY_DIR}/CMakeFiles/${TARGET}.dir/build.make)
    add_test(NAME ${TARGET}_makefile_validate
        COMMAND sh -c "make -f ${MAKEFILE} ${TARGET} -n > ${BINARY_DIR}/${TARGET}_validate_commands.txt && \
        python ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/file_pattern_search.py ${BINARY_DIR}/${TARGET}_validate_commands.txt -- ${SEARCH_PATTERNS}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

endfunction()
