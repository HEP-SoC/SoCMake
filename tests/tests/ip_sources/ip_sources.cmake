include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_sources)
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_sources(${IP} SYSTEMVERILOG
        ${CDIR}/svfile1.sv
        ${CDIR}/svfile2.sv
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        )

# TEST SYSTEMVERILOG include directories

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    ip_sources(${IP} SYSTEMVERILOG
        ${CDIR}/svfile3.sv
        ${CDIR}/svfile4.sv
        )

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv;${CDIR}/svfile3.sv;${CDIR}/svfile4.sv")


# TEST VERILOG include directories
    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile3.v
        ${CDIR}/vfile4.v
        )

    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/vfile3.v;${CDIR}/vfile4.v")

# TEST Warning asserted on unknown language
    ip_sources(${IP} FAKELANG
        ${CDIR}/fakelang.fake
        )
    ct_assert_prints("Language not supported: FAKELANG")

endfunction()
