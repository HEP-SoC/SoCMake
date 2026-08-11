include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_sources_excluded_ips_filters_dependency_sources)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(gis_top)
    set(TOP ${IP})
    add_ip(gis_mid)
    set(MID ${IP})
    ip_sources(${IP} VERILOG ${CDIR}/mid.v)
    add_ip(gis_other)
    set(OTHER ${IP})
    ip_sources(${IP} VERILOG ${CDIR}/other.v)

    ip_link(${TOP} ${MID})
    ip_link(${TOP} ${OTHER})

    # EXCLUDED_IPS is forwarded from get_ip_sources() to get_ip_links(), so sources
    # belonging to an excluded IP are left out of the result.
    get_ip_sources(result ${TOP} VERILOG EXCLUDED_IPS ${MID})
    ct_assert_equal(result "${CDIR}/other.v")
endfunction()
