include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_link1)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})

# Define the following dependency graph
# The First two files will come from ip4.
# The following 2 can come from either ip2 or ip3 how flat_graph is implemented, but both are legal
# The last 2 files will come from ip1
#            ┌─────┐
#    ┌───────┤ ip1 ├────┐
#    │       └─────┘    │
#    │                  │
#    │                  │
# ┌──▼──┐           ┌───▼──┐
# │ ip2 │           │ ip3  │
# └──┬──┘           └──┬───┘
#    │                 │
#    │                 │
#    │      ┌──────┐   │
#    └──────► ip4  │◄──┘
#           └──────┘

    add_ip(ip1
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )
    ip_sources(${IP} VERILOG ip1_f1.v ip1_f2.v)
    set(IP1 ${IP})

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )
    ip_sources(${IP} VERILOG ip2_f1.v ip2_f2.v)
    set(IP2 ${IP})

    add_ip(ip3
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )
    ip_sources(${IP} VERILOG ip3_f1.v ip3_f2.v)
    set(IP3 ${IP})

    add_ip(ip4
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )
    ip_sources(${IP} VERILOG ip4_f1.v ip4_f2.v)
    set(IP4 ${IP})

    ip_link(${IP1} ${IP2} ${IP3})
    ip_link(${IP2} ${IP4})
    ip_link(${IP3} ${IP4})

    get_ip_sources(V_SOURCES ${IP1} VERILOG)

    list(SUBLIST V_SOURCES 0 2 CURRENT_V_FILES)
    ct_assert_equal(CURRENT_V_FILES "ip4_f1.v;ip4_f2.v")

    list(SUBLIST V_SOURCES 2 4 CURRENT_V_FILES)
    if("${CURRENT_V_FILES}" STREQUAL "ip2_f1.v;ip2_f2.v;ip3_f1.v;ip3_f2.v")
        ct_assert_true(TRUE)
    elseif("${CURRENT_V_FILES}" STREQUAL "ip3_f1.v;ip3_f2.v;ip3_f1.v;ip3_f2.v")
        ct_assert_true(TRUE)
    else()
        ct_assert_true(FALSE)
    endif()

    list(SUBLIST V_SOURCES 6 2 CURRENT_V_FILES)
    ct_assert_equal(CURRENT_V_FILES "ip1_f1.v;ip1_f2.v")
endfunction()
