#[[[
# Creates a CTest test that performs a dry-run build of ``TARGET`` and verifies
# that each of the given ``PATTERNS`` appears in the generated build commands.
# Sets ``CTEST_NAME`` in the parent scope to the name of the created test.
#
# Works with both Make and Ninja generators.
#
# :param TARGET: The CMake target whose build commands are inspected.
# :type TARGET: string
# :param PATTERNS: One or more substrings that must be present in the build commands.
# :type PATTERNS: list of strings
#
#]]
function(add_test_build_commands_match_patterns TARGET)
    if(ARGC LESS 2)
        message(
            FATAL_ERROR
            "Provide search patterns as arguments to ${CMAKE_CURRENT_FUNCTION}"
        )
    endif()

    set(SEARCH_PATTERNS "")
    foreach(pattern ${ARGN})
        set(SEARCH_PATTERNS "${SEARCH_PATTERNS} \"${pattern}\"")
    endforeach()

    include(CTest)
    enable_testing()

    get_target_property(BINARY_DIR ${TARGET} BINARY_DIR)

    if(CMAKE_GENERATOR MATCHES "Ninja")
        set(DRY_RUN_CMD
            "${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR} -v -n ${TARGET}"
        )
    else()
        set(DRY_RUN_CMD
            "make -f ${BINARY_DIR}/CMakeFiles/${TARGET}.dir/build.make ${TARGET} -n"
        )
    endif()

    add_test(
        NAME ${TARGET}_makefile_validate
        COMMAND
            sh -c
            "${DRY_RUN_CMD} > ${BINARY_DIR}/${TARGET}_validate_commands.txt && \
        python ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/file_pattern_search.py ${BINARY_DIR}/${TARGET}_validate_commands.txt -- ${SEARCH_PATTERNS}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set(CTEST_NAME ${TARGET}_makefile_validate PARENT_SCOPE)
endfunction()
