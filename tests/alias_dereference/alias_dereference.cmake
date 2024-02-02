include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME alias_dereference)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    set(IP_REF ${IP_VENDOR}::${IP_LIBRARY}::${IP_NAME}::${IP_VERSION})
    ct_assert_target_has_property(${IP_REF} ALIASED_TARGET)

    alias_dereference(IP_DEREF ${IP_REF})

    ct_assert_target_does_not_have_property(${IP_DEREF} ALIASED_TARGET)
    ct_assert_equal(IP_DEREF ${IP})
endfunction()
