include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME check_languages_additional)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    set(SOCMAKE_ADDITIONAL_LANGUAGES FAKELANG)
    check_languages(FAKELANG)
endfunction()
