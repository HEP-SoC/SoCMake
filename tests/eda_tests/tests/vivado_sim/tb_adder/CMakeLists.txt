cmake_minimum_required(VERSION 3.25)
project(tb_adder_vivado_sim NONE)

include(SoCMakeConfig)

option_string(TB_LANG "language of testbench" verilog)
option_string(DUT_LANG "language of dut" verilog)

add_subdirectory("../../../test_files/rtl/tb_adder/${TB_LANG}/" tb)

vivado_sim(tb_adder RUN_ARGS --onerror quit --onfinish quit)

