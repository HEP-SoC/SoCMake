include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_link_nodepend_sources_reachable)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(nodep_top VENDOR test LIBRARY nodep VERSION 1.0.0)
    set(TOP ${IP})
    add_ip(nodep_dep VENDOR test LIBRARY nodep VERSION 1.0.0)
    ip_sources(${IP} VERILOG ${CDIR}/ip1_f1.v)

    ip_link(${TOP} ${IP} NODEPEND)

    # Verify no build dependency was created
    alias_dereference(_top_real ${TOP})
    get_target_property(DEPS ${_top_real} MANUALLY_ADDED_DEPENDENCIES)
    ct_assert_equal(DEPS "DEPS-NOTFOUND")

    # NODEPEND skips add_dependencies() but target_link_libraries() still runs,
    # so sources from the dependency are reachable via get_ip_sources
    get_ip_sources(V_SOURCES ${TOP} VERILOG)
    ct_assert_equal(V_SOURCES "${CDIR}/ip1_f1.v")
endfunction()

set(TEST_NAME ip_link_self_link_nodepend_fatal)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(nodep_self VENDOR test LIBRARY nodep VERSION 2.0.0)
    ip_link(${IP} ${IP} NODEPEND)
endfunction()
