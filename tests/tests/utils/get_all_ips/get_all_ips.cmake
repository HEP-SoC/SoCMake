include("${CMAKE_CURRENT_LIST_DIR}/../../../../CMakeLists.txt")

set(TEST_NAME get_all_ips_contains_created_ips)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(gai_ip1 VENDOR test LIBRARY getall VERSION 1.0.0)
    set(IP1 ${IP})
    add_ip(gai_ip2 VENDOR test LIBRARY getall VERSION 2.0.0)
    set(IP2 ${IP})

    get_all_ips(ALL_IPS)

    ct_assert_list(ALL_IPS)
    list(FIND ALL_IPS ${IP1} idx1)
    list(FIND ALL_IPS ${IP2} idx2)
    if(idx1 EQUAL -1 OR idx2 EQUAL -1)
        ct_assert_true(FALSE)
    else()
        ct_assert_true(TRUE)
    endif()
endfunction()

set(TEST_NAME get_all_ips_excludes_non_ip_targets)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # add_library creates a target without the IP_NAME property set by add_ip
    add_library(plain_interface_lib INTERFACE)

    get_all_ips(ALL_IPS)

    list(FIND ALL_IPS plain_interface_lib idx)
    ct_assert_equal(idx -1)
endfunction()
