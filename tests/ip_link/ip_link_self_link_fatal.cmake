include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_link_self_link_fatal)

ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(ip1)
    add_ip(ip2)
    add_ip(ip3)
    ip_link(ip1 ip2 ip3 ip1)
endfunction()
