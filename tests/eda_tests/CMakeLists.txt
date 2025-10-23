cmake_minimum_required(VERSION 3.25)
project(eda_tools_test)

include("${CMAKE_CURRENT_LIST_DIR}/cmake/eda_test.cmake")

include(CTest)

# Verilator
eda_test("tests/verilator/tb_adder" "tb_adder_v_verilator" TARGET_NAME tb_adder_verilator )

# Iverilog
eda_test("tests/iverilog/tb_adder" "tb_adder_v_iverilog" TARGET_NAME tb_adder_iverilog )

# GHDL
eda_test("tests/ghdl" "tb_adder_vhdl_ghdl" TARGET_NAME tb_adder_ghdl)

# Modelsim
eda_test("tests/modelsim/tb_adder" 
         "tb_adder_modelsim" 
         TARGET_NAME tb_adder_modelsim MODELSIM
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=verilog"
     )
eda_test("tests/modelsim/tb_adder"
         "tb_adder_vhdl_modelsim"
         TARGET_NAME tb_adder_modelsim MODELSIM
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=vhdl"
     )
eda_test("tests/modelsim/tb_adder"
         "tb_adder_verilog_vhdl_modelsim"
         TARGET_NAME tb_adder_modelsim MODELSIM
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=vhdl"
     )
eda_test("tests/modelsim/tb_adder"
         "tb_adder_vhdl_verilog_modelsim"
         TARGET_NAME tb_adder_modelsim MODELSIM
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=verilog"
     )


# xcelium
eda_test("tests/xcelium/tb_adder" 
         "tb_adder_xcelium" 
         TARGET_NAME tb_adder_xcelium
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=verilog"
     )
eda_test("tests/xcelium/tb_adder"
         "tb_adder_vhdl_xcelium"
         TARGET_NAME tb_adder_xcelium
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=vhdl"
     )
eda_test("tests/xcelium/tb_adder"
         "tb_adder_verilog_vhdl_xcelium"
         TARGET_NAME tb_adder_xcelium
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=vhdl"
     )
eda_test("tests/xcelium/tb_adder"
         "tb_adder_vhdl_verilog_xcelium"
         TARGET_NAME tb_adder_xcelium
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=verilog"
     )

# vivado_sim
eda_test("tests/vivado_sim/tb_adder" 
         "tb_adder_vivado_sim" 
         TARGET_NAME tb_adder_vivado_sim
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=verilog"
     )
eda_test("tests/vivado_sim/tb_adder"
         "tb_adder_vhdl_vivado_sim"
         TARGET_NAME tb_adder_vivado_sim
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=vhdl"
     )
eda_test("tests/vivado_sim/tb_adder"
         "tb_adder_verilog_vhdl_vivado_sim"
         TARGET_NAME tb_adder_vivado_sim
         DEFINES "-DTB_LANG=verilog -DDUT_LANG=vhdl"
     )
eda_test("tests/vivado_sim/tb_adder"
         "tb_adder_vhdl_verilog_vivado_sim"
         TARGET_NAME tb_adder_vivado_sim
         DEFINES "-DTB_LANG=vhdl -DDUT_LANG=verilog"
     )
