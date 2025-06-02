add_ip(socmake::tests::file_sets::1.0 NO_ALIAS)

ip_sources(${IP} VERILOG FILE_SET rtl_files
    ${CMAKE_CURRENT_LIST_DIR}/i2c_top.v
    ${CMAKE_CURRENT_LIST_DIR}/i2c_rx.v
    ${CMAKE_CURRENT_LIST_DIR}/i2c_tx.v
)

ip_sources(${IP} VHDL FILE_SET rtl_files
    ${CMAKE_CURRENT_LIST_DIR}/fifo.vhd
)

ip_sources(${IP} VERILOG FILE_SET rtl_files HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/i2c_defs.vh
    ${CMAKE_CURRENT_LIST_DIR}/apb_defs.vh
)

ip_sources(${IP} SYSTEMVERILOG FILE_SET simulation
    ${CMAKE_CURRENT_LIST_DIR}/i2c_tb.sv
    ${CMAKE_CURRENT_LIST_DIR}/clk_gen.sv
)

ip_sources(${IP} SYSTEMVERILOG FILE_SET simulation HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/i2c_tb_defs.svh
)

ip_sources(${IP} VERILOG FILE_SET synthesis
    ${CMAKE_CURRENT_LIST_DIR}/i2c_cells.v
)

ip_sources(${IP} SYSTEMVERILOG FILE_SET synthesis
    ${CMAKE_CURRENT_LIST_DIR}/clk_gate.sv
)


ip_sources(${IP} IPXACT
    ${CMAKE_CURRENT_LIST_DIR}/file_sets.xml)

ip_link(${IP}
)

