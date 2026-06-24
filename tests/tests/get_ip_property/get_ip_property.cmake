include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME get_ip_property_no_deps_returns_own_only)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(test::getip::gip_parent1::1.0.0)
    set(PARENT ${IP})
    add_ip(test::getip::gip_child1::1.0.0)
    ip_sources(${IP} VERILOG ${CDIR}/child1.v)

    ip_link(${PARENT} ${IP})

    # With NO_DEPS: parent has no sources of its own
    get_ip_property(result ${PARENT} VERILOG_DEFAULT_SOURCES NO_DEPS)
    ct_assert_equal(result "")
endfunction()

set(TEST_NAME get_ip_property_with_deps_traverses_graph)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(test::getip::gip_parent2::1.0.0)
    set(PARENT ${IP})
    add_ip(test::getip::gip_child2::1.0.0)
    ip_sources(${IP} VERILOG ${CDIR}/child2.v)

    ip_link(${PARENT} ${IP})

    # Without NO_DEPS: child's sources are visible from parent
    get_ip_property(result ${PARENT} VERILOG_DEFAULT_SOURCES)
    ct_assert_equal(result "${CDIR}/child2.v")
endfunction()

set(TEST_NAME get_ip_property_custom_property)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(test::getip::gip_top3::1.0.0)
    set(TOP ${IP})
    add_ip(test::getip::gip_sub3::1.0.0)
    set_target_properties(${IP} PROPERTIES MY_CUSTOM_PROP "hello")

    ip_link(${TOP} ${IP})

    # Property from dependency is visible without NO_DEPS
    get_ip_property(result ${TOP} MY_CUSTOM_PROP)
    ct_assert_equal(result "hello")

    # Property from dependency is invisible with NO_DEPS
    get_ip_property(result_nodeps ${TOP} MY_CUSTOM_PROP NO_DEPS)
    ct_assert_equal(result_nodeps "")
endfunction()
