include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME check_languages_fatal)

ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    message(FATAL_ERROR "This code will run in a test")
    set(SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL TRUE)
    check_languages(FAKELANG)
endfunction()
