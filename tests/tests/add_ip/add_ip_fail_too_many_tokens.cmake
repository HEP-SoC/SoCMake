# This tests should fail because its not allowed to have different than 4 or 1 tokens in `ip_link()` call
include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME add_ip_fail_5_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::ip::0.0.1::token)
endfunction()

set(TEST_NAME add_ip_fail_6_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::ip::0.0.1::token1::token2)
endfunction()

set(TEST_NAME add_ip_fail_7_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::ip::0.0.1::token1::token2::token3)
endfunction()
