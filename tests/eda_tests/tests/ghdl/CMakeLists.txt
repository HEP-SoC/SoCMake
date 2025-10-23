cmake_minimum_required(VERSION 3.25)
project(tb_adder_ghdl NONE)

include(SoCMakeConfig)

option_string(TB_LANG "language of testbench" vhdl)
option_string(DUT_LANG "language of dut" vhdl)

message(STATUS "TB_LANG IS ${TB_LANG}")
add_subdirectory("../../test_files/rtl/tb_adder/${TB_LANG}/" tb)

ghdl(tb_adder)

