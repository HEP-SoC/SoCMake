cmake_minimum_required(VERSION 3.25)
project(tb_adder_xcelium NONE)

include(SoCMakeConfig)

option_string(TB_LANG "language of testbench" verilog)
option_string(DUT_LANG "language of dut" verilog)

add_subdirectory("../../../test_files/rtl/tb_adder/${TB_LANG}/" tb)

xcelium(tb_adder VHDL_COMPILE_ARGS -v200x)
