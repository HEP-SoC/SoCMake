include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

add_ip(ip
    VENDOR vendor
    LIBRARY lib
    VERSION 1.2.3
    )
ct_assert_target_exists(vendor::lib::ip::1.2.3)
ct_assert_target_exists(vendor__lib__ip__1.2.3)

ct_assert_equal(IP_NAME "ip")
ct_assert_equal(IP_VENDOR "vendor")
ct_assert_equal(IP_LIBRARY "lib")
ct_assert_equal(IP_VERSION "1.2.3")
ct_assert_target_exists(${IP_VENDOR}__${IP_LIBRARY}__${IP_NAME}__${IP_VERSION})
