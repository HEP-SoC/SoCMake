# This tests should fail because its not allowed to have different than 4 or 1 tokens in `ip_link()` call
include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME add_ip_fail_3_tokens_vendor_lib_ip)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::ip)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_vendor_lib_version)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::0.0.1)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_lib_ip_version)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(lib::ip::0.0.1)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_empty_token_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(::::vendor)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_empty_token_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(::vendor::lib)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_empty_token_3)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::::lib)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_empty_token_4)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib::)
endfunction()

set(TEST_NAME add_ip_fail_3_tokens_empty_token_5)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::::)
endfunction()

