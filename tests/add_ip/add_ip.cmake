include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME add_ip)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    ## Test full add_ip() call
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )
    ct_assert_target_exists(vendor::lib::ip::1.2.3)
    ct_assert_target_exists(vendor__lib__ip__1.2.3)

    ct_assert_equal(IP vendor__lib__ip__1.2.3)
    ct_assert_equal(IP_NAME "ip")
    ct_assert_equal(IP_VENDOR "vendor")
    ct_assert_equal(IP_LIBRARY "lib")
    ct_assert_equal(IP_VERSION "1.2.3")
    ct_assert_target_exists(${IP_VENDOR}__${IP_LIBRARY}__${IP_NAME}__${IP_VERSION})

    add_ip(ip4
        VERSION 1.1.1
        )
    ct_assert_target_exists(ip4::1.1.1)
    ct_assert_target_exists(ip4__1.1.1)

    ## Test shortened add_ip() call 
    add_ip(vendor2::lib2::ip2::1.2.2)

    ct_assert_target_exists(vendor2::lib2::ip2::1.2.2)
    ct_assert_target_exists(vendor2__lib2__ip2__1.2.2)

    ct_assert_equal(IP vendor2__lib2__ip2__1.2.2)
    ct_assert_equal(IP_NAME "ip2")
    ct_assert_equal(IP_VENDOR "vendor2")
    ct_assert_equal(IP_LIBRARY "lib2")
    ct_assert_equal(IP_VERSION "1.2.2")
    ct_assert_target_exists(${IP_VENDOR}__${IP_LIBRARY}__${IP_NAME}__${IP_VERSION})

endfunction()
