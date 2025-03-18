include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_sources_get_multilang)
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

    ip_sources(${IP} VHDL
        ${CDIR}/vhdlfile1.vhdl
        ${CDIR}/vhdlfile2.vhdl
        )

    get_ip_sources(SOURCES ${IP} VERILOG SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(SOURCES ${IP} VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/vhdlfile1.vhdl;${CDIR}/vhdlfile2.vhdl;${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(SOURCES ${IP} VERILOG VHDL)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/vhdlfile1.vhdl;${CDIR}/vhdlfile2.vhdl")

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.4
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile3.v
        ${CDIR}/vfile4.v
        )

    ip_sources(${IP} VHDL
        ${CDIR}/vhdlfile3.vhdl
        ${CDIR}/vhdlfile4.vhdl
        )

    ip_link(vendor::lib::ip::1.2.3 vendor::lib::ip2::1.2.4)

    get_ip_sources(SOURCES vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/vfile3.v;${CDIR}/vfile4.v;${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/vhdlfile3.vhdl;${CDIR}/vhdlfile4.vhdl;${CDIR}/vhdlfile1.vhdl;${CDIR}/vhdlfile2.vhdl;${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(SOURCES vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG NO_DEPS)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/vfile1.v;${CDIR}/vfile2.v;${CDIR}/vhdlfile1.vhdl;${CDIR}/vhdlfile2.vhdl;${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")
endfunction()

