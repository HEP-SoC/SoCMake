# This test will succed because its allowed to have short notation in `ip_link(ip)` call
include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME add_ip_1_token)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(vendor::lib::ip1::0.0.1)
    ct_assert_target_exists(vendor::lib::ip1::0.0.1)
    ct_assert_target_exists(vendor__lib__ip1__0.0.1)
    ct_assert_equal(IP vendor__lib__ip1__0.0.1)
    ct_assert_equal(IP_VENDOR vendor)
    ct_assert_equal(IP_LIBRARY lib)
    ct_assert_equal(IP_VERSION 0.0.1)

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        )
    ct_assert_target_exists(vendor::lib::ip2)
    ct_assert_equal(IP vendor__lib__ip2)
    ct_assert_equal(IP_VENDOR vendor)
    ct_assert_equal(IP_LIBRARY lib)
    ct_assert_not_defined(IP_VERSION)

    add_ip(ip3)
    ct_assert_target_exists(ip3)
    ct_assert_equal(IP ip3)
    ct_assert_not_defined(IP_VENDOR)
    ct_assert_not_defined(IP_LIBRARY)
    ct_assert_not_defined(IP_VERSION)
endfunction()
