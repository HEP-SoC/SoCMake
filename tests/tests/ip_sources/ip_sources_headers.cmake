include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_sources_headers)
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip)

    ip_sources(${IP} SYSTEMVERILOG
        ${CDIR}/svfile1.sv
        ${CDIR}/svfile2.sv
        HEADERS
        ${CDIR}/svheader1.svh
        ${CDIR}/svheader2.svh
            
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG HEADERS)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svheader1.svh;${CDIR}/svheader2.svh")

    ip_sources(${IP} SYSTEMVERILOG
        ${CDIR}/svfile3.sv
        ${CDIR}/svfile4.sv
        HEADERS
        ${CDIR}/svheader3.svh
        ${CDIR}/svheader4.svh
        )

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv;${CDIR}/svfile3.sv;${CDIR}/svfile4.sv")

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG HEADERS)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svheader1.svh;${CDIR}/svheader2.svh;${CDIR}/svheader3.svh;${CDIR}/svheader4.svh")


# TEST VERILOG include directories
    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(V_SOURCES ${IP} VERILOG HEADERS)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile3.v
        ${CDIR}/vfile4.v
        HEADERS
        ${CDIR}/vheader3.vh
        ${CDIR}/vheader4.vh
        )

    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/vfile3.v;${CDIR}/vfile4.v")

    get_ip_sources(V_SOURCES ${IP} VERILOG HEADERS)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh;${CDIR}/vheader3.vh;${CDIR}/vheader4.vh")

endfunction()

