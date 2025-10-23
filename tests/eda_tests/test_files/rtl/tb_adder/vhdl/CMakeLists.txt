option_string(DUT_LANG "language of dut" vhdl)

add_ip(tb_adder)
ip_sources(${IP} VHDL tb_adder.vhdl)
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../../adder/${DUT_LANG}/" adder)
ip_link(tb_adder adder)
