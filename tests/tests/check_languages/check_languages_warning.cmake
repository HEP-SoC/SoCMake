include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME check_languages_warning)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    check_languages(FAKELANG)
    ct_assert_prints("Language not supported")
endfunction()


