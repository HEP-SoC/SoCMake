include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_sources_file_set_1)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip1)

    ip_sources(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        ${CDIR}/svfile1.sv
        ${CDIR}/svfile2.sv
        )

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "")
endfunction()

set(TEST_NAME ip_sources_file_set_2)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip2)

    ip_sources(${IP} VHDL FILE_SET SYNTHESIS
        ${CDIR}/vhdlfile1.vhd
        ${CDIR}/vhdlfile2.vhd
        )

    ip_sources(${IP} VHDL FILE_SET SYNTHESIS
        ${CDIR}/vhdlfile3.vhd
        ${CDIR}/vhdlfile4.vhd
        )

    get_ip_sources(sources ${IP} VHDL)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd;${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_3)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip3)

    ip_sources(${IP} VHDL FILE_SET SYNTHESIS
        ${CDIR}/vhdlfile1.vhd
        ${CDIR}/vhdlfile2.vhd
        )

    ip_sources(${IP} VHDL FILE_SET SIMULATION
        ${CDIR}/vhdlfile3.vhd
        ${CDIR}/vhdlfile4.vhd
        )

    get_ip_sources(sources ${IP} VHDL)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd;${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")

    get_ip_sources(sources ${IP} VHDL FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS SIMULATION SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd;${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS SYNTHESIS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd;${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")
endfunction()

set(TEST_NAME ip_sources_file_set_4)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip4)

    ip_sources(${IP} VHDL FILE_SET SYNTHESIS
        ${CDIR}/vhdlfile1.vhd
        ${CDIR}/vhdlfile2.vhd
        )

    ip_sources(${IP} VHDL
        ${CDIR}/vhdlfile3.vhd
        ${CDIR}/vhdlfile4.vhd
        )

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        )

    get_ip_sources(sources ${IP} VHDL)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd;${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")

    get_ip_sources(sources ${IP} VHDL FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile1.vhd;${CDIR}/vhdlfile2.vhd")

    get_ip_sources(sources ${IP} VERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS SIMULATION SYNTHESIS)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ${IP} VHDL FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vhdlfile3.vhd;${CDIR}/vhdlfile4.vhd")
endfunction()

set(TEST_NAME ip_sources_file_set_headers_1)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_headers_1)

    ip_sources(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        ${CDIR}/svfile1.sv
        ${CDIR}/svfile2.sv
        HEADERS
        ${CDIR}/svheader1.svh
        ${CDIR}/svheader2.svh
        )

    get_ip_sources(headers ${IP} SYSTEMVERILOG HEADERS)
    ct_assert_list(headers)
    ct_assert_equal(headers "${CDIR}/svheader1.svh;${CDIR}/svheader2.svh")

    get_ip_sources(sources ${IP} SYSTEMVERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/svfile1.sv;${CDIR}/svfile2.sv")

    get_ip_sources(sources ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_headers_2)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_headers_2)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        HEADERS
        ${CDIR}/vheader3.vh
        ${CDIR}/vheader4.vh
        )

    get_ip_sources(sources ${IP} VERILOG HEADERS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh;${CDIR}/vheader3.vh;${CDIR}/vheader4.vh")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_headers_3)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_headers_3)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    ip_sources(${IP} VERILOG FILE_SET SIMULATION
        HEADERS
        ${CDIR}/vheader3.vh
        ${CDIR}/vheader4.vh
        )

    get_ip_sources(sources ${IP} VERILOG HEADERS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh;${CDIR}/vheader3.vh;${CDIR}/vheader4.vh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader3.vh;${CDIR}/vheader4.vh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS SYNTHESIS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh;${CDIR}/vheader3.vh;${CDIR}/vheader4.vh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS SIMULATION SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader3.vh;${CDIR}/vheader4.vh;${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_headers_4)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_headers_4)

    ip_sources(${IP} VERILOG
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    get_ip_sources(sources ${IP} VERILOG HEADERS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ${IP} VERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")
endfunction()

set(TEST_NAME ip_sources_file_set_links_1)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_links_11)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    add_ip(ip_links_12)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile3.v
        ${CDIR}/vfile4.v
        HEADERS
        ${CDIR}/vheader3.vh
        ${CDIR}/vheader4.vh
    )

    ip_link(ip_links_11 ip_links_12)


    get_ip_sources(sources ip_links_11 VERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile3.v;${CDIR}/vfile4.v;${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ip_links_11 VERILOG FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile3.v;${CDIR}/vfile4.v;${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(headers ip_links_11 VERILOG HEADERS)
    ct_assert_list(headers)
    ct_assert_equal(headers "${CDIR}/vheader3.vh;${CDIR}/vheader4.vh;${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(headers ip_links_11 VERILOG HEADERS FILE_SETS SYNTHESIS)
    ct_assert_list(headers)
    ct_assert_equal(headers "${CDIR}/vheader3.vh;${CDIR}/vheader4.vh;${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ip_links_11 VERILOG HEADERS FILE_SETS DEFAULT)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_links_2)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_links_21)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile1.v
        ${CDIR}/vfile2.v
        HEADERS
        ${CDIR}/vheader1.vh
        ${CDIR}/vheader2.vh
        )

    add_ip(ip_links_22)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/vfile3.v
        ${CDIR}/vfile4.v
        HEADERS
        ${CDIR}/vheader3.vh
        ${CDIR}/vheader4.vh
    )

    ip_link(ip_links_21 ip_links_22)


    get_ip_sources(sources ip_links_21 VERILOG NO_DEPS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(sources ip_links_21 VERILOG FILE_SETS SYNTHESIS NO_DEPS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/vfile1.v;${CDIR}/vfile2.v")

    get_ip_sources(headers ip_links_21 VERILOG HEADERS NO_DEPS)
    ct_assert_list(headers)
    ct_assert_equal(headers "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(headers ip_links_21 VERILOG HEADERS FILE_SETS SYNTHESIS NO_DEPS)
    ct_assert_list(headers)
    ct_assert_equal(headers "${CDIR}/vheader1.vh;${CDIR}/vheader2.vh")

    get_ip_sources(sources ip_links_21 VERILOG HEADERS FILE_SETS DEFAULT NO_DEPS)
    ct_assert_not_list(sources)
    ct_assert_equal(sources "")
endfunction()

set(TEST_NAME ip_sources_file_set_links_3)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip_links_31)

    ip_sources(${IP} VERILOG FILE_SET SYNTHESIS
        ${CDIR}/ip1_file1.v
        ${CDIR}/ip1_file2.v
        )
    ip_sources(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        ${CDIR}/ip1_file1.sv
        ${CDIR}/ip1_file2.sv
    )

    add_ip(ip_links_32)

    ip_sources(${IP} VERILOG FILE_SET SIMULATION
        ${CDIR}/ip2_file1.v
        ${CDIR}/ip2_file2.v
    )

    ip_sources(${IP} SYSTEMVERILOG FILE_SET SYNTHESIS
        ${CDIR}/ip2_file1.sv
        ${CDIR}/ip2_file2.sv
    )

    ip_link(ip_links_31 ip_links_32)

    get_ip_sources(sources ip_links_31 SYSTEMVERILOG VERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.sv;${CDIR}/ip2_file2.sv;${CDIR}/ip2_file1.v;${CDIR}/ip2_file2.v;${CDIR}/ip1_file1.sv;${CDIR}/ip1_file2.sv;${CDIR}/ip1_file1.v;${CDIR}/ip1_file2.v")
    

    get_ip_sources(sources ip_links_31 SYSTEMVERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.sv;${CDIR}/ip2_file2.sv;${CDIR}/ip1_file1.sv;${CDIR}/ip1_file2.sv")

    get_ip_sources(sources ip_links_31 VERILOG)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.v;${CDIR}/ip2_file2.v;${CDIR}/ip1_file1.v;${CDIR}/ip1_file2.v")

    get_ip_sources(sources ip_links_31 VERILOG FILE_SETS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.v;${CDIR}/ip2_file2.v")

    get_ip_sources(sources ip_links_31 VERILOG FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip1_file1.v;${CDIR}/ip1_file2.v")

    get_ip_sources(sources ip_links_31 SYSTEMVERILOG VERILOG FILE_SETS SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.sv;${CDIR}/ip2_file2.sv;${CDIR}/ip1_file1.v;${CDIR}/ip1_file2.v")

    get_ip_sources(sources ip_links_31 VERILOG SYSTEMVERILOG FILE_SETS SIMULATION)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.v;${CDIR}/ip2_file2.v;${CDIR}/ip1_file1.sv;${CDIR}/ip1_file2.sv")

    get_ip_sources(sources ip_links_31 SYSTEMVERILOG VERILOG FILE_SETS SIMULATION SYNTHESIS)
    ct_assert_list(sources)
    ct_assert_equal(sources "${CDIR}/ip2_file1.sv;${CDIR}/ip2_file2.sv;${CDIR}/ip2_file1.v;${CDIR}/ip2_file2.v;${CDIR}/ip1_file1.sv;${CDIR}/ip1_file2.sv;${CDIR}/ip1_file1.v;${CDIR}/ip1_file2.v")

endfunction()
