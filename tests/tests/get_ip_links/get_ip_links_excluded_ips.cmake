include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME get_ip_links_excludes_ip_and_its_exclusive_deps)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # gil_top1 -> gil_mid1 -> gil_leaf1
    add_ip(gil_top1)
    add_ip(gil_mid1)
    add_ip(gil_leaf1)
    ip_link(gil_top1 gil_mid1)
    ip_link(gil_mid1 gil_leaf1)

    # Excluding gil_mid1 also drops gil_leaf1, since it's only reachable through gil_mid1
    get_ip_links(result gil_top1 EXCLUDED_IPS gil_mid1)
    ct_assert_equal(result "gil_top1")
endfunction()

set(TEST_NAME get_ip_links_excluded_ip_dependency_reachable_via_other_path_kept)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # gil_top2 -> gil_mid2 -> gil_shared2
    # gil_top2 -> gil_mid2 -> gil_mid_only2
    # gil_top2 -> gil_other2 -> gil_shared2
    add_ip(gil_top2)
    add_ip(gil_mid2)
    add_ip(gil_other2)
    add_ip(gil_shared2)
    add_ip(gil_mid_only2)
    ip_link(gil_top2 gil_mid2)
    ip_link(gil_top2 gil_other2)
    ip_link(gil_mid2 gil_shared2)
    ip_link(gil_mid2 gil_mid_only2)
    ip_link(gil_other2 gil_shared2)

    # Excluding gil_mid2 drops gil_mid_only2 (only reachable through gil_mid2), but
    # gil_shared2 stays since gil_other2 (not excluded) also links it directly.
    get_ip_links(result gil_top2 EXCLUDED_IPS gil_mid2)
    ct_assert_equal(result "gil_shared2;gil_other2;gil_top2")
endfunction()

set(TEST_NAME get_ip_links_no_deps_with_excluded_ips_filters_direct_children)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # gil_top3 -> gil_mid3
    # gil_top3 -> gil_other3
    add_ip(gil_top3)
    add_ip(gil_mid3)
    add_ip(gil_other3)
    ip_link(gil_top3 gil_mid3)
    ip_link(gil_top3 gil_other3)

    # NO_DEPS + EXCLUDED_IPS never needs the graph walk: it just filters the direct children
    get_ip_links(result gil_top3 NO_DEPS EXCLUDED_IPS gil_other3)
    ct_assert_equal(result "gil_mid3")
endfunction()

set(TEST_NAME get_ip_links_cache_unaffected_by_excluded_call)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # gil_top4 -> gil_mid4 -> gil_leaf4
    # gil_top4 -> gil_other4
    add_ip(gil_top4)
    add_ip(gil_mid4)
    add_ip(gil_leaf4)
    add_ip(gil_other4)
    ip_link(gil_top4 gil_mid4)
    ip_link(gil_mid4 gil_leaf4)
    ip_link(gil_top4 gil_other4)

    set(expected_full "gil_leaf4;gil_mid4;gil_other4;gil_top4")

    # Populate (and cache) the full, unfiltered graph first
    get_ip_links(before gil_top4)
    ct_assert_equal(before "${expected_full}")

    # A filtered call must not be written into (or read from) the FLAT_GRAPH cache
    get_ip_links(excl gil_top4 EXCLUDED_IPS gil_mid4)
    ct_assert_equal(excl "gil_other4;gil_top4")

    # The cached, unfiltered result must still be intact afterwards
    get_ip_links(after gil_top4)
    ct_assert_equal(after "${expected_full}")
endfunction()

set(TEST_NAME get_ip_links_cycle_broken_by_excluding_cycle_edge)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    # gil_a5 -> gil_b5 -> gil_c5 -> gil_a5 (cycle)
    add_ip(gil_a5)
    add_ip(gil_b5)
    add_ip(gil_c5)
    ip_link(gil_a5 gil_b5 NODEPEND)
    ip_link(gil_b5 gil_c5 NODEPEND)
    ip_link(gil_c5 gil_a5 NODEPEND)

    # Excluding gil_c5 removes the edge that closes the cycle, so no FATAL_ERROR is raised
    get_ip_links(result gil_a5 EXCLUDED_IPS gil_c5)
    ct_assert_equal(result "gil_b5;gil_a5")
endfunction()

set(TEST_NAME get_ip_links_cycle_still_detected_when_unrelated_ip_excluded)
ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    # gil_a6 -> gil_b6 -> gil_c6 -> gil_a6 (cycle), gil_d6 is unrelated to the cycle
    add_ip(gil_a6)
    add_ip(gil_b6)
    add_ip(gil_c6)
    add_ip(gil_d6)
    ip_link(gil_a6 gil_b6 NODEPEND)
    ip_link(gil_b6 gil_c6 NODEPEND)
    ip_link(gil_c6 gil_a6 NODEPEND)

    # Excluding an IP that isn't part of the cycle must not suppress cycle detection
    get_ip_links(result gil_a6 EXCLUDED_IPS gil_d6)
endfunction()
