include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_sources_get_multilang)
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip1
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_sources(${IP} SYSTEMVERILOG
        ${CDIR}/ip1_svfile1.sv
        ${CDIR}/ip1_svfile2.sv
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/ip1_vfile1.v
        ${CDIR}/ip1_vfile2.v
        )

    ip_sources(${IP} VHDL
        ${CDIR}/ip1_vhdlfile1.vhdl
        ${CDIR}/ip1_vhdlfile2.vhdl
        )

    get_ip_sources(SOURCES ${IP} VERILOG SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/ip1_vfile1.v;${CDIR}/ip1_vfile2.v;${CDIR}/ip1_svfile1.sv;${CDIR}/ip1_svfile2.sv")

    get_ip_sources(SOURCES ${IP} VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/ip1_vhdlfile1.vhdl;${CDIR}/ip1_vhdlfile2.vhdl;${CDIR}/ip1_svfile1.sv;${CDIR}/ip1_svfile2.sv")

    get_ip_sources(SOURCES ${IP} VERILOG VHDL)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/ip1_vfile1.v;${CDIR}/ip1_vfile2.v;${CDIR}/ip1_vhdlfile1.vhdl;${CDIR}/ip1_vhdlfile2.vhdl")

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.4
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/ip2_vfile1.v
        ${CDIR}/ip2_vfile2.v
        )

    ip_sources(${IP} VHDL
        ${CDIR}/ip2_vhdlfile1.vhdl
        ${CDIR}/ip2_vhdlfile2.vhdl
        )

    ip_link(vendor::lib::ip1::1.2.3 vendor::lib::ip2::1.2.4)

    get_ip_sources(SOURCES vendor::lib::ip1::1.2.3 VERILOG VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/ip2_vfile1.v;${CDIR}/ip2_vfile2.v;${CDIR}/ip2_vhdlfile1.vhdl;${CDIR}/ip2_vhdlfile2.vhdl;${CDIR}/ip1_vfile1.v;${CDIR}/ip1_vfile2.v;${CDIR}/ip1_vhdlfile1.vhdl;${CDIR}/ip1_vhdlfile2.vhdl;${CDIR}/ip1_svfile1.sv;${CDIR}/ip1_svfile2.sv")

    get_ip_sources(SOURCES vendor::lib::ip1::1.2.3 VERILOG VHDL SYSTEMVERILOG NO_DEPS)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "${CDIR}/ip1_vfile1.v;${CDIR}/ip1_vfile2.v;${CDIR}/ip1_vhdlfile1.vhdl;${CDIR}/ip1_vhdlfile2.vhdl;${CDIR}/ip1_svfile1.sv;${CDIR}/ip1_svfile2.sv")
endfunction()

