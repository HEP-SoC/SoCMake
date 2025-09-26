include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME add_ip_vendor_FALSE)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    ## Test full add_ip() call
    add_ip(FALSE::lib::ip::0.1)
    ct_assert_target_exists(FALSE::lib::ip::0.1)
    ct_assert_target_exists(FALSE__lib__ip__0.1)

    ct_assert_equal(IP FALSE__lib__ip__0.1)
    ct_assert_equal(IP_NAME "ip")
    ct_assert_equal(IP_VENDOR "FALSE")
    ct_assert_equal(IP_LIBRARY "lib")
    ct_assert_equal(IP_VERSION "0.1")
    ct_assert_target_exists(${IP_VENDOR}__${IP_LIBRARY}__${IP_NAME}__${IP_VERSION})

endfunction()


