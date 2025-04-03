# This tests should fail because its not allowed to have different than 4 or 1 tokens in `ip_link()` call
include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME add_ip_fail_2_tokens_name_version)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(ip1::0.0.1)
endfunction()

set(TEST_NAME add_ip_fail_2_tokens_vendor_name)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::ip1)
endfunction()

set(TEST_NAME add_ip_fail_2_tokens_vendor_lib)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::lib)
endfunction()

set(TEST_NAME add_ip_fail_2_tokens_vendor_version)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(vendor::0.0.1)
endfunction()

set(TEST_NAME add_ip_fail_2_tokens_lib_version)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(lib::0.0.1)
endfunction()


set(TEST_NAME add_ip_fail_2_tokens_empty_token_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(lib::)
endfunction()

set(TEST_NAME add_ip_fail_2_tokens_empty_token_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(::lib)
endfunction()
