include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

# --- create_ip_vlnv ---

set(TEST_NAME create_ip_vlnv_full)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    create_ip_vlnv(OUT ip VENDOR v LIBRARY l VERSION 1.2.3)
    ct_assert_equal(OUT "v__l__ip__1.2.3")
endfunction()

set(TEST_NAME create_ip_vlnv_no_vendor)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    create_ip_vlnv(OUT ip LIBRARY l VERSION 1.2.3)
    ct_assert_equal(OUT "l__ip__1.2.3")
endfunction()

set(TEST_NAME create_ip_vlnv_name_only)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    create_ip_vlnv(OUT myip)
    ct_assert_equal(OUT "myip")
endfunction()

set(TEST_NAME create_ip_vlnv_no_version)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    create_ip_vlnv(OUT ip VENDOR v LIBRARY l)
    ct_assert_equal(OUT "v__l__ip")
endfunction()

set(TEST_NAME create_ip_vlnv_unknown_arg_fails)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    create_ip_vlnv(OUT ip VENDOR v BADARG foo)
endfunction()

# --- parse_ip_vlnv ---

set(TEST_NAME parse_ip_vlnv_full)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    parse_ip_vlnv("v::l::myip::2.0.1" VENDOR LIBRARY IP_NAME VERSION)
    ct_assert_equal(VENDOR  "v")
    ct_assert_equal(LIBRARY "l")
    ct_assert_equal(IP_NAME "myip")
    ct_assert_equal(VERSION "2.0.1")
endfunction()

set(TEST_NAME parse_ip_vlnv_name_only)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    parse_ip_vlnv("myip" VENDOR LIBRARY IP_NAME VERSION)
    ct_assert_equal(IP_NAME "myip")
endfunction()

set(TEST_NAME parse_ip_vlnv_fail_2_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    parse_ip_vlnv("v::myip" VENDOR LIBRARY IP_NAME VERSION)
endfunction()

set(TEST_NAME parse_ip_vlnv_fail_3_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    parse_ip_vlnv("v::l::myip" VENDOR LIBRARY IP_NAME VERSION)
endfunction()

set(TEST_NAME parse_ip_vlnv_fail_5_tokens)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    parse_ip_vlnv("v::l::myip::2.0.1::extra" VENDOR LIBRARY IP_NAME VERSION)
endfunction()
