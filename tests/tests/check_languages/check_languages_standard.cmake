include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME check_languages_standard)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    check_languages(SYSTEMRDL)
    check_languages(SYSTEMVERILOG)
    check_languages(VERILOG)
    check_languages(VHDL)
endfunction()
