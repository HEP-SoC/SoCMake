include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME add_ip_name_FALSE)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    ## Test full add_ip() call
    add_ip(vendor::lib::FALSE::0.1)
    ct_assert_target_exists(vendor::lib::FALSE::0.1)
    ct_assert_target_exists(vendor__lib__FALSE__0.1)

    ct_assert_equal(IP vendor__lib__FALSE__0.1)
    ct_assert_equal(IP_NAME "FALSE")
    ct_assert_equal(IP_VENDOR "vendor")
    ct_assert_equal(IP_LIBRARY "lib")
    ct_assert_equal(IP_VERSION "0.1")
    ct_assert_target_exists(${IP_VENDOR}__${IP_LIBRARY}__${IP_NAME}__${IP_VERSION})

endfunction()




