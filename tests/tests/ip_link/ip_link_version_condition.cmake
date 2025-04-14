include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_link_version_condition_0)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    add_ip(v::l::ip3::4.40.100)
    add_ip(v::l::ip4::100.120.5)


    ip_link(v::l::top
            v::l::ip2::3.9.2
            v::l::ip3::4.40.100
            v::l::ip4::100.120.5
        )
endfunction()

set(TEST_NAME ip_link_version_condition_1)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)


    ip_link(v::l::top "v::l::ip2 >= 3.9.2")
    ip_link(v::l::top "v::l::ip2 >  3.9.1")
    ip_link(v::l::top "v::l::ip2 >  3.9.1")
    ip_link(v::l::top "v::l::ip2 <  3.9.3")
    ip_link(v::l::top "v::l::ip2 <= 3.9.3")
    ip_link(v::l::top "v::l::ip2 <= 3.9.2")
    ip_link(v::l::top "v::l::ip2 == 3.9.2")

    ip_link(v::l::top "v::l::ip2 >= 3.8.2")
    ip_link(v::l::top "v::l::ip2 >  3.8.1")
    ip_link(v::l::top "v::l::ip2 >  3.8.1")
    ip_link(v::l::top "v::l::ip2 <  3.10.3")
    ip_link(v::l::top "v::l::ip2 <= 3.10.3")
    ip_link(v::l::top "v::l::ip2 <= 3.10.2")

    ip_link(v::l::top "v::l::ip2 >= 3.8.3")
    ip_link(v::l::top "v::l::ip2 >  3.8.2")
    ip_link(v::l::top "v::l::ip2 >  3.8.2")
    ip_link(v::l::top "v::l::ip2 <  3.10.2")
    ip_link(v::l::top "v::l::ip2 <= 3.10.2")
    ip_link(v::l::top "v::l::ip2 <= 3.10.1")

    ip_link(v::l::top "v::l::ip2 >= 2.9.3")
    ip_link(v::l::top "v::l::ip2 >  2.9.2")
    ip_link(v::l::top "v::l::ip2 >  2.9.2")
    ip_link(v::l::top "v::l::ip2 <  4.9.2")
    ip_link(v::l::top "v::l::ip2 <= 4.9.2")
    ip_link(v::l::top "v::l::ip2 <= 4.9.1")
endfunction()


set(TEST_NAME ip_link_version_condition_mult_0)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)

    ip_link(v::l::top "v::l::ip2 >= 3.9.2, < 4.0.0")
    ip_link(v::l::top "v::l::ip2 < 3.9.3, > 3.9.1")
    ip_link(v::l::top "v::l::ip2 == 3.9.2, < 3.20.2")
endfunction()

set(TEST_NAME ip_link_version_condition_mult_1)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    add_ip(v::l::ip3::4.40.100)
    add_ip(v::l::ip4::100.120.5)


    ip_link(v::l::top
            "v::l::ip2 >=3.9.0, <= 3.9.5"
            "v::l::ip3 >= 4.0.100, < 4.100.0"
            "v::l::ip4 < 200.200.200, > 100.100.100"
        )
endfunction()

set(TEST_NAME ip_link_version_condition_gteq_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 >= 3.9.3")
endfunction()

set(TEST_NAME ip_link_version_condition_gteq_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 >= 3.10.2")
endfunction()

set(TEST_NAME ip_link_version_condition_gteq_fail_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 >= 4.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_gt_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 > 3.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_gt_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 > 3.10.2")
endfunction()

set(TEST_NAME ip_link_version_condition_gt_fail_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 > 4.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_lt_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 < 3.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_lt_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 < 3.8.2")
endfunction()

set(TEST_NAME ip_link_version_condition_lt_fail_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 < 2.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_lteq_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 <= 3.9.1")
endfunction()

set(TEST_NAME ip_link_version_condition_lteq_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 <= 3.8.2")
endfunction()

set(TEST_NAME ip_link_version_condition_lteq_fail_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 <= 2.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_eq_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 == 3.9.1")
endfunction()

set(TEST_NAME ip_link_version_condition_eq_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 == 3.8.2")
endfunction()

set(TEST_NAME ip_link_version_condition_eq_fail_2)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 == 2.9.2")
endfunction()

set(TEST_NAME ip_link_version_condition_mult_fail_0)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 > 2.9.2, < 3.9.2")
endfunction()


set(TEST_NAME ip_link_version_condition_mult_fail_1)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(v::l::top::1.5.1)
    add_ip(v::l::ip2::3.9.2)
    ip_link(v::l::top "v::l::ip2 > 3.9.2, < 4.9.2")
endfunction()
