include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME flatten1)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    set(t ip_${TEST_NAME})
    add_ip(${t}_1)
    add_ip(${t}_2)
    add_ip(${t}_3)
    add_ip(${t}_4)

    ip_link(${t}_3 ${t}_4)
    ip_link(${t}_2 ${t}_4 ${t}_3)
    ip_link(${t}_1 ${t}_2)

    get_ip_links(links ${t}_1)

endfunction()


