include("${CMAKE_CURRENT_LIST_DIR}/../../../../CMakeLists.txt")

set(TEST_NAME ipxact_import)
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip_from_ipxact(${CDIR}/file_sets.xml)

    ct_assert_target_exists(socmake::tests::file_sets::1.0)
    ct_assert_target_exists(socmake__tests__file_sets__1.0)

    get_ip_sources(sources ${IP} VERILOG)
    ct_assert_equal(sources "${CDIR}/i2c_top.v;${CDIR}/i2c_rx.v;${CDIR}/i2c_tx.v;${CDIR}/i2c_cells.v")

    get_ip_sources(sources ${IP} VHDL)
    ct_assert_equal(sources "${CDIR}/fifo.vhd")

    get_ip_sources(sources ${IP} SYSTEMVERILOG)
    ct_assert_equal(sources "${CDIR}/i2c_tb.sv;${CDIR}/clk_gen.sv;${CDIR}/clk_gate.sv")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS rtl_files)
    ct_assert_equal(sources "${CDIR}/i2c_top.v;${CDIR}/i2c_rx.v;${CDIR}/i2c_tx.v")

    get_ip_sources(sources ${IP} VERILOG FILE_SETS synthesis)
    ct_assert_equal(sources "${CDIR}/i2c_cells.v")

    get_ip_sources(sources ${IP} SYSTEMVERILOG FILE_SETS simulation)
    ct_assert_equal(sources "${CDIR}/i2c_tb.sv;${CDIR}/clk_gen.sv")

    get_ip_sources(sources ${IP} SYSTEMVERILOG HEADERS FILE_SETS simulation)
    ct_assert_equal(sources "${CDIR}/i2c_tb_defs.svh")

    get_ip_sources(sources ${IP} VERILOG HEADERS FILE_SETS rtl_files)
    ct_assert_equal(sources "${CDIR}/i2c_defs.vh;${CDIR}/apb_defs.vh")

    get_ip_sources(sources ${IP} VERILOG SYSTEMVERILOG HEADERS FILE_SETS rtl_files simulation)
    ct_assert_equal(sources "${CDIR}/i2c_defs.vh;${CDIR}/apb_defs.vh;${CDIR}/i2c_tb_defs.svh")

    get_ip_include_directories(incdirs ${IP} VERILOG)
    ct_assert_equal(incdirs "${CDIR}")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG)
    ct_assert_equal(incdirs "${CDIR}")

    file(REMOVE "${CDIR}/socmake__tests__file_setsConfig.cmake")
endfunction()
