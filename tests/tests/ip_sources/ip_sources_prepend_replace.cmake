include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_sources_prepend)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(prepend_ip VENDOR test LIBRARY prepend VERSION 1.0.0)

    ip_sources(${IP} VERILOG ${CDIR}/file1.v ${CDIR}/file2.v)
    ip_sources(${IP} VERILOG PREPEND ${CDIR}/file0.v)

    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/file0.v;${CDIR}/file1.v;${CDIR}/file2.v")
endfunction()

set(TEST_NAME ip_sources_replace)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(replace_ip VENDOR test LIBRARY replace VERSION 1.0.0)

    ip_sources(${IP} VERILOG ${CDIR}/file1.v ${CDIR}/file2.v)
    ip_sources(${IP} VERILOG REPLACE ${CDIR}/file3.v)

    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_equal(V_SOURCES "${CDIR}/file3.v")
endfunction()

set(TEST_NAME ip_sources_no_deps)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(nodeps_parent VENDOR test LIBRARY nodeps VERSION 1.0.0)
    set(PARENT ${IP})
    add_ip(nodeps_child VENDOR test LIBRARY nodeps VERSION 1.0.0)
    ip_sources(${IP} VERILOG ${CDIR}/child_file.v)

    ip_link(${PARENT} ${IP})

    # NO_DEPS: only parent's own sources (none)
    get_ip_sources(V_SOURCES ${PARENT} VERILOG NO_DEPS)
    ct_assert_equal(V_SOURCES "")

    # Without NO_DEPS: child's sources are included
    get_ip_sources(V_SOURCES_ALL ${PARENT} VERILOG)
    ct_assert_equal(V_SOURCES_ALL "${CDIR}/child_file.v")
endfunction()
