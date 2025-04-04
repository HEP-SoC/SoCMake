# Test relative include directories paths, the behaviour is matching the CMake behaviour of target_include_directories():
# Changed in version 3.13: Relative source file paths are interpreted as being relative to the current source directory (i.e. CMAKE_CURRENT_SOURCE_DIR). See policy CMP0076.

include("${CMAKE_CURRENT_LIST_DIR}/../../../../CMakeLists.txt")
set(THIS_DIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_include_directories_rel_path)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    execute_process(
        COMMAND cmake -S ${THIS_DIR}/test
                      -B ${CMAKE_BINARY_DIR}/${TEST_NAME}/build
                      COMMAND_ERROR_IS_FATAL ANY
                  )
endfunction()
