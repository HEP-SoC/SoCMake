include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME add_ip_description)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        DESCRIPTION "Simple description"
        )
    ct_assert_target_has_property(${IP} DESCRIPTION)
    get_target_property(_desc ${IP} DESCRIPTION)
    ct_assert_equal(_desc "Simple description")

    add_ip(ip2
        DESCRIPTION "Simpler description"
        )
    ct_assert_target_has_property(${IP} DESCRIPTION)
    get_target_property(_desc ${IP} DESCRIPTION)
    ct_assert_equal(_desc "Simpler description")

    add_ip(vendor2::lib::ip::0.0.1
        DESCRIPTION "Even simpler description"
        )
    ct_assert_target_has_property(${IP} DESCRIPTION)
    get_target_property(_desc ${IP} DESCRIPTION)
    ct_assert_equal(_desc "Even simpler description")

endfunction()
